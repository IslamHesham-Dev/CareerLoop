"""The one object you talk to: `CompanyJobsConnector`.

    from company_jobs_connector import CompanyJobsConnector

    connector = CompanyJobsConnector(anthropic_api_key="...")
    jobs = connector.get_company_jobs("anthropic")
"""

from __future__ import annotations

import re
import requests
from bs4 import BeautifulSoup
from langchain_anthropic import ChatAnthropic

from .models import CompanyJob, LLMJobExtraction


class CompanyJobsConnector:
    """A connector that dynamically fetches and LLM-parses ATS job boards."""

    def __init__(self, anthropic_api_key: str, timeout: int = 15) -> None:
        self.timeout = timeout
        # Using Haiku since it is fast and excellent at simple extraction
        self.llm = ChatAnthropic(
            model="claude-3-haiku-20240307",
            temperature=0,
            api_key=anthropic_api_key,
        )
        self.structured_llm = self.llm.with_structured_output(LLMJobExtraction)

    def _normalize_name(self, name: str) -> str:
        """Strip spaces and special chars to form a URL-friendly ATS slug."""
        name = name.lower()
        name = re.sub(r'[^a-z0-9]', '', name)
        # Handle common suffixes people might type
        for suffix in ["inc", "llc", "corp", "technologies"]:
            if name.endswith(suffix):
                name = name[: -len(suffix)]
        return name

    def _fetch_ats_html(self, company_name: str) -> str | None:
        """Attempt to download the raw HTML from common ATS boards."""
        slug = self._normalize_name(company_name)
        
        # We test Greenhouse, Lever, and AshbyHQ URLs
        urls_to_try = [
            f"https://boards.greenhouse.io/{slug}",
            f"https://jobs.lever.co/{slug}",
            # Ashby often uses the exact name
            f"https://jobs.ashbyhq.com/{slug}",
        ]
        
        for url in urls_to_try:
            try:
                resp = requests.get(url, timeout=self.timeout)
                if resp.ok:
                    # Some ATSs return 200 for "Not Found" but the page is tiny or explicitly says it
                    if len(resp.text) > 1000:
                        return resp.text
            except requests.RequestException:
                continue
                
        return None

    def _extract_text(self, html: str) -> str:
        """Strip HTML tags to reduce token usage significantly."""
        soup = BeautifulSoup(html, "html.parser")
        # Remove scripts and styles
        for element in soup(["script", "style", "nav", "footer"]):
            element.extract()
        text = soup.get_text(separator="\n", strip=True)
        return text

    def get_company_jobs(self, company_name: str) -> list[CompanyJob]:
        """Fetch and parse all open roles for a specific company.
        
        Returns an empty list if the company is not found or has no open roles.
        """
        html = self._fetch_ats_html(company_name)
        if not html:
            return []

        clean_text = self._extract_text(html)
        
        # If the text is incredibly short, it's likely a 404 page
        if len(clean_text) < 100:
            return []

        prompt = (
            f"You are an expert data extractor. Below is the raw text extracted from the career page "
            f"for '{company_name}'. Please extract all the available job postings you can find. "
            f"If there are no jobs or this looks like a 'Not Found' page, return an empty list.\n\n"
            f"--- CAREER PAGE TEXT ---\n{clean_text[:50000]}\n--- END TEXT ---"
        )

        try:
            extraction = self.structured_llm.invoke(prompt)
            if not extraction or not hasattr(extraction, "jobs"):
                return []
                
            jobs: list[CompanyJob] = []
            for job in extraction.jobs:
                jobs.append(
                    CompanyJob(
                        title=job.title,
                        location=job.location,
                        department=job.department,
                        link=job.link,
                    )
                )
            return jobs
        except Exception as e:
            # If the LLM extraction fails, return empty
            return []
