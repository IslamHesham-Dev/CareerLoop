"""Fast structured access to the public listing feed used by Swelist.

The connector reads, caches, and filters the underlying JSON feed directly,
then exposes stable `JobPosting` objects without spawning a CLI subprocess.

    from swelist_connector import SwelistConnector

    connector = SwelistConnector()
    jobs = connector.get_postings(role="internship", timeframe="lastday")
    for job in jobs:
        print(job.title, job.company)
"""

from __future__ import annotations

import json
import re
import threading
import time
from dataclasses import replace
from datetime import UTC, datetime
from typing import Any, Literal
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

from .models import JobPosting


class SwelistConnector:
    """Cached programmatic access to Swelist's underlying listing feed."""

    _TIMEFRAME_SECONDS = {
        "lastday": 24 * 60 * 60,
        "lastweek": 7 * 24 * 60 * 60,
        "lastmonth": 30 * 24 * 60 * 60,
    }

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

    def __init__(self, timeout: int = 20, cache_ttl: int = 10 * 60) -> None:
        self.timeout = timeout
        self.cache_ttl = cache_ttl
        self._metadata_cache: dict[
            str,
            tuple[float, dict[str, dict[str, Any]]],
        ] = {}
        self._cache_lock = threading.RLock()

    def get_postings(
        self,
        role: Literal["internship", "newgrad"] = "internship",
        timeframe: Literal[
            "all", "lastday", "lastweek", "lastmonth"
        ] = "lastday",
        location: str | None = None,
    ) -> list[JobPosting]:
        """Fetch and filter the structured feed used by Swelist.

        The feed is cached because downloading it and launching the Swelist
        CLI for every request made interactive searches unnecessarily slow.
        """
        metadata = self._load_metadata(role)
        return self._structured_postings(
            metadata,
            location=location,
            timeframe=timeframe,
        )

    def _load_metadata(
        self,
        role: Literal["internship", "newgrad"],
    ) -> dict[str, dict[str, Any]]:
        """Read and cache the JSON feed used by Swelist."""
        now = time.monotonic()
        with self._cache_lock:
            cached = self._metadata_cache.get(role)
            if cached and now - cached[0] < self.cache_ttl:
                return cached[1]

        try:
            request = Request(
                self.FEEDS[role],
                headers={"User-Agent": "CareerLoop/1.0"},
            )
            with urlopen(request, timeout=self.timeout) as response:
                payload = json.load(response)
        except Exception:
            # A stale feed is better than blocking or returning nothing during
            # a temporary GitHub/raw-content outage.
            if cached:
                with self._cache_lock:
                    self._metadata_cache[role] = (now, cached[1])
                return cached[1]
            return {}
        if not isinstance(payload, list):
            if cached:
                with self._cache_lock:
                    self._metadata_cache[role] = (now, cached[1])
                return cached[1]
            return {}
        indexed = {
            self._normalized_url(str(item.get("url", ""))): item
            for item in payload
            if isinstance(item, dict) and item.get("url")
        }
        with self._cache_lock:
            self._metadata_cache[role] = (now, indexed)
        return indexed

    def _structured_postings(
        self,
        metadata: dict[str, dict[str, Any]],
        *,
        location: str | None,
        timeframe: Literal[
            "all", "lastday", "lastweek", "lastmonth"
        ] = "all",
    ) -> list[JobPosting]:
        requested = [
            value.strip().casefold()
            for value in (location or "").split(",")
            if value.strip()
        ]
        postings: list[JobPosting] = []
        cutoff = None
        if timeframe != "all":
            cutoff = datetime.now(UTC).timestamp() - self._TIMEFRAME_SECONDS[
                timeframe
            ]
        for item in metadata.values():
            if item.get("active") is False or item.get("is_visible") is False:
                continue
            if cutoff is not None:
                try:
                    if float(item.get("date_posted")) < cutoff:
                        continue
                except (TypeError, ValueError):
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
