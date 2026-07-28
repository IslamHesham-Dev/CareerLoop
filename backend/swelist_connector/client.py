"""The one object you talk to: `SwelistConnector`.

Since `swelist` is a CLI tool and does not expose a native Python API for importing,
this connector acts as a wrapper that invokes the CLI via subprocess and parses
its text output into structured Python objects (`JobPosting`).

    from swelist_connector import SwelistConnector

    connector = SwelistConnector()
    jobs = connector.get_postings(role="internship", timeframe="lastday")
    for job in jobs:
        print(job.title, job.company)
"""

from __future__ import annotations

import os
import json
import re
import subprocess
import sys
from dataclasses import replace
from datetime import UTC, datetime
from typing import Any, Literal
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

from .models import JobPosting


class SwelistConnector:
    """A programmatic wrapper around the swelist CLI tool."""

    FEEDS = {
        "internship": (
            "https://raw.githubusercontent.com/SimplifyJobs/"
            "Summer2025-Internships/refs/heads/dev/.github/scripts/listings.json"
        ),
        "newgrad": (
            "https://raw.githubusercontent.com/SimplifyJobs/"
            "New-Grad-Positions/refs/heads/dev/.github/scripts/listings.json"
        ),
    }

    def __init__(self, timeout: int = 45) -> None:
        self.timeout = timeout

    def get_postings(
        self,
        role: Literal["internship", "newgrad"] = "internship",
        timeframe: Literal[
            "all", "lastday", "lastweek", "lastmonth"
        ] = "lastday",
        location: str | None = None,
    ) -> list[JobPosting]:
        """Fetch Swelist jobs, retaining the full structured listing metadata."""
        metadata = self._load_metadata(role)
        if timeframe == "all":
            return self._structured_postings(metadata, location=location)

        # Use the active interpreter instead of relying on PATH. Render starts
        # Uvicorn from ``.venv/bin`` without activating the virtualenv, so a
        # bare ``swelist`` subprocess is not reliably discoverable there.
        cmd = [
            sys.executable,
            "-m",
            "swelist.main",
            "run",
            "--role",
            role,
            "--timeframe",
            timeframe,
        ]
        if location:
            cmd.extend(["--location", location])

        try:
            # We use capture_output=True and text=True to get stdout as a string.
            # swelist uses rich, so we strip out ANSI sequences implicitly if possible,
            # but usually redirecting stdout makes it fall back to plain text.
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=self.timeout,
                check=True,
                env={**os.environ, "NO_COLOR": "1"},
            )
        except FileNotFoundError:
            raise RuntimeError(
                "Swelist is not installed in the backend environment."
            ) from None
        except subprocess.TimeoutExpired:
            raise RuntimeError("The swelist command timed out.") from None
        except subprocess.CalledProcessError as exc:
            detail = (exc.stderr or exc.stdout or "").strip()
            raise RuntimeError(
                f"The swelist command failed: {detail or 'unknown error'}"
            ) from None

        jobs: list[JobPosting] = []
        current_job: dict[str, str] = {}
        parsing_link = False
        ansi = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")

        # Parse the block format output from swelist
        for raw_line in result.stdout.splitlines():
            line = ansi.sub("", raw_line).strip()
            if not line:
                if "company" in current_job and "title" in current_job:
                    self._append_job(jobs, current_job)
                    current_job = {}
                parsing_link = False
                continue

            if line.startswith("Company:"):
                current_job = {"company": line.split(":", 1)[1].strip()}
                parsing_link = False
            elif line.startswith("Title:") and "company" in current_job:
                current_job["title"] = line.split(":", 1)[1].strip()
            elif line.lower().startswith("location") and "company" in current_job:
                loc_str = line.split(":", 1)[1].strip()
                if loc_str.startswith("['") and loc_str.endswith("']"):
                    loc_str = loc_str[2:-2]
                current_job["location"] = loc_str
            elif line.startswith("Link:") and "company" in current_job:
                parsing_link = True
                val = line.split(":", 1)[1].strip()
                if val:
                    current_job["link"] = val
            elif parsing_link and "company" in current_job:
                current_job["link"] = current_job.get("link", "") + line

        # Catch trailing job if output didn't end with a newline
        if "company" in current_job and "title" in current_job:
            self._append_job(jobs, current_job)

        unique = {job.link: job for job in jobs if job.link}
        return [
            self._enrich(job, metadata.get(self._normalized_url(job.link)))
            for job in unique.values()
        ]

    def _load_metadata(
        self,
        role: Literal["internship", "newgrad"],
    ) -> dict[str, dict[str, Any]]:
        """Read the same JSON feed used by Swelist and index it by apply URL."""
        try:
            request = Request(
                self.FEEDS[role],
                headers={"User-Agent": "CareerLoop/1.0"},
            )
            with urlopen(request, timeout=self.timeout) as response:
                payload = json.load(response)
        except Exception:
            return {}
        if not isinstance(payload, list):
            return {}
        return {
            self._normalized_url(str(item.get("url", ""))): item
            for item in payload
            if isinstance(item, dict) and item.get("url")
        }

    def _structured_postings(
        self,
        metadata: dict[str, dict[str, Any]],
        *,
        location: str | None,
    ) -> list[JobPosting]:
        requested = [
            value.strip().casefold()
            for value in (location or "").split(",")
            if value.strip()
        ]
        postings: list[JobPosting] = []
        for item in metadata.values():
            if item.get("active") is False or item.get("is_visible") is False:
                continue
            locations = [
                str(value).strip()
                for value in item.get("locations", [])
                if str(value).strip()
            ]
            searchable = " | ".join(locations).casefold()
            if requested and not any(value in searchable for value in requested):
                continue
            link = str(item.get("url", "")).strip()
            parsed = urlparse(link)
            if parsed.scheme not in {"http", "https"} or not parsed.netloc:
                continue
            postings.append(
                self._enrich(
                    JobPosting(
                        company=str(item.get("company_name", "")).strip(),
                        title=str(item.get("title", "")).strip(),
                        location=" · ".join(locations),
                        link=link,
                    ),
                    item,
                )
            )
        return postings

    @classmethod
    def _enrich(
        cls,
        job: JobPosting,
        item: dict[str, Any] | None,
    ) -> JobPosting:
        if not item:
            return replace(
                job,
                company_logo_url=cls._company_logo_url(
                    job.company,
                    job.link,
                ),
            )
        locations = tuple(
            str(value).strip()
            for value in item.get("locations", [])
            if str(value).strip()
        )
        raw_degrees = item.get("degrees", [])
        degrees = tuple(
            str(value).strip()
            for value in raw_degrees
            if str(value).strip()
        ) if isinstance(raw_degrees, list) else ()
        return replace(
            job,
            external_id=str(item.get("id") or "").strip() or None,
            location=" · ".join(locations) or job.location,
            locations=locations,
            category=str(item.get("category") or "").strip() or None,
            posted_at=cls._timestamp(item.get("date_posted")),
            updated_at=cls._timestamp(item.get("date_updated")),
            sponsorship=str(item.get("sponsorship") or "").strip() or None,
            degrees=degrees,
            company_profile_url=(
                str(item.get("company_url") or "").strip() or None
            ),
            company_logo_url=cls._company_logo_url(job.company, job.link),
            active=bool(item.get("active", True)),
            metadata={
                "source": item.get("source"),
                "is_visible": item.get("is_visible"),
            },
        )

    @staticmethod
    def _timestamp(value: Any) -> str | None:
        try:
            return datetime.fromtimestamp(float(value), UTC).isoformat()
        except (TypeError, ValueError, OSError):
            return None

    @staticmethod
    def _normalized_url(value: str) -> str:
        return value.strip().rstrip("/")

    @classmethod
    def _company_logo_url(cls, company: str, link: str) -> str:
        """Build a favicon URL from the employer domain inferred from its apply URL."""
        parsed = urlparse(link)
        host = parsed.netloc.casefold().split(":")[0]
        path_parts = [part for part in parsed.path.split("/") if part]
        domain = host
        if "myworkdayjobs.com" in host:
            brand = host.split(".", 1)[0].split("-", 1)[0]
            domain = f"{re.sub(r'\\d+$', '', brand)}.com"
        elif host in {"jobs.lever.co", "boards.greenhouse.io"} and path_parts:
            domain = f"{path_parts[0]}.com"
        elif "smartrecruiters.com" in host and path_parts:
            domain = f"{re.sub(r'\\d+$', '', path_parts[0].casefold())}.com"
        elif host.startswith(("jobs.", "careers.", "apply.")):
            domain = host.split(".", 1)[1]
        elif host in {
            "job-boards.greenhouse.io",
            "boards.eu.greenhouse.io",
        } and path_parts:
            domain = f"{path_parts[0]}.com"
        if not domain or "." not in domain:
            slug = re.sub(r"[^a-z0-9]+", "", company.casefold())
            domain = f"{slug}.com"
        return (
            "https://www.google.com/s2/favicons?"
            f"domain_url={quote(f'https://{domain}', safe='')}&sz=128"
        )

    @staticmethod
    def _append_job(
        jobs: list[JobPosting],
        value: dict[str, str],
    ) -> None:
        link = value.get("link", "").replace(" ", "")
        parsed = urlparse(link)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            return
        jobs.append(
            JobPosting(
                company=value.get("company", ""),
                title=value.get("title", ""),
                location=value.get("location", ""),
                link=link,
            )
        )
