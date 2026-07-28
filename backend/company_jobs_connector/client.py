from __future__ import annotations

import os
import re
import requests
from bs4 import BeautifulSoup
from langchain_anthropic import ChatAnthropic

from .models import CompanyJob, LLMJobExtraction


class CompanyJobsConnector:
    """A connector that dynamically discovers ATS job boards and LLM-parses open roles."""

    def __init__(
        self,
        anthropic_api_key: str,
        serper_api_key: str | None = None,
        model: str = "claude-haiku-4-5",
        timeout: int = 15,
    ) -> None:
        self.timeout = timeout
        # Falling back to a raw env var (rather than only the caller-supplied
        # value) is deliberate here: this connector has no other way to be
        # configured outside app.config.Settings, which is where callers
        # should be getting this from - see app.agent.factory.get_company_jobs.
        self.serper_api_key = serper_api_key or os.getenv("SERPER_API_KEY")

        self.llm = ChatAnthropic(
            model=model,
            temperature=0,
            api_key=anthropic_api_key,
        )
        self.structured_llm = self.llm.with_structured_output(LLMJobExtraction)

    # Minimum length of *rendered text* (not raw HTML/JS bytes) a page must
    # have to count as a real careers page. Some ATS providers (Ashby in
    # particular) return a 200 OK, multi-KB HTML shell even for a company
    # slug with no real job board behind it - the page is a client-rendered
    # app shell with almost no server-side text, so checking raw HTML size
    # alone (the old behavior) accepts it as a false positive. This is the
    # same threshold get_company_jobs already uses to guard the LLM call
    # against garbage input, applied earlier so a bad URL is never accepted
    # as "found" in the first place.
    _MIN_CAREERS_PAGE_TEXT_LENGTH = 100

    def _looks_like_a_careers_page(self, html: str) -> bool:
        return len(self._extract_text(html)) >= self._MIN_CAREERS_PAGE_TEXT_LENGTH

    def _discover_careers_url(self, company_name: str) -> str | None:
        """Dynamically locates the exact job board URL using Google Search (via Serper).

        Falls back to hardcoded ATS patterns if no search API key is available.
        """
        if self.serper_api_key:
            url = "https://google.serper.dev/search"
            # Targeted query restricting to common ATS systems and general career pages
            query = (
                f"{company_name} jobs careers "
                f"(site:greenhouse.io OR site:lever.co OR site:ashbyhq.com OR site:myworkdayjobs.com)"
            )
            payload = {"q": query}
            headers = {
                "X-API-KEY": self.serper_api_key,
                "Content-Type": "application/json",
            }

            try:
                response = requests.post(
                    url, headers=headers, json=payload, timeout=self.timeout
                )
                if response.ok:
                    data = response.json()
                    organic_results = data.get("organic", [])
                    if organic_results and "link" in organic_results[0]:
                        candidate = organic_results[0]["link"]
                        html = self._fetch_page_html(candidate)
                        if html and self._looks_like_a_careers_page(html):
                            return candidate
                        # A search hit that turned out to be a dead/empty page
                        # is worth falling through to the ATS guesses below,
                        # not trusting blindly.
            except requests.RequestException:
                pass  # Fall through to standard fallback logic if search fails

        # Fallback: Static string normalization & candidate URL probing
        slug = re.sub(r"[^a-z0-9]", "", company_name.lower())
        for suffix in ["inc", "llc", "corp", "technologies"]:
            if slug.endswith(suffix):
                slug = slug[: -len(suffix)]

        fallback_urls = [
            f"https://boards.greenhouse.io/{slug}",
            f"https://jobs.lever.co/{slug}",
            f"https://jobs.ashbyhq.com/{slug}",
        ]

        for target_url in fallback_urls:
            try:
                resp = requests.get(target_url, timeout=self.timeout)
                if (
                    resp.ok
                    and len(resp.text) > 1000
                    and self._looks_like_a_careers_page(resp.text)
                ):
                    return target_url
            except requests.RequestException:
                continue

        return None

    def _fetch_page_html(self, target_url: str) -> str | None:
        """Downloads raw HTML from a resolved target URL."""
        headers = {
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            )
        }
        try:
            resp = requests.get(target_url, headers=headers, timeout=self.timeout)
            if resp.ok and len(resp.text) > 1000:
                return resp.text
        except requests.RequestException:
            pass
        return None

    def _extract_text(self, html: str) -> str:
        """Strips non-content HTML tags to reduce LLM token usage."""
        soup = BeautifulSoup(html, "html.parser")
        for element in soup(["script", "style", "nav", "footer", "header", "noscript"]):
            element.extract()
        return soup.get_text(separator="\n", strip=True)

    def get_company_jobs(self, company_name: str) -> list[CompanyJob]:
        """Fetch and parse all open roles for a specific company.

        Returns an empty list if the company is not found or has no open roles.
        """
        target_url = self._discover_careers_url(company_name)
        if not target_url:
            return []

        html = self._fetch_page_html(target_url)
        if not html:
            return []

        clean_text = self._extract_text(html)

        # Guard against 404s or empty shell pages
        if len(clean_text) < 100:
            return []

        prompt = (
            f"You are an expert data extractor. Below is raw text extracted from the career page "
            f"for '{company_name}' ({target_url}). Extract all available job postings you can find.\n"
            f"If there are no jobs listed or this is an invalid page, return an empty list.\n\n"
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
        except Exception:
            return []