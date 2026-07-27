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
import re
import subprocess
import sys
from typing import Literal
from urllib.parse import urlparse

from .models import JobPosting


class SwelistConnector:
    """A programmatic wrapper around the swelist CLI tool."""

    def __init__(self, timeout: int = 45) -> None:
        self.timeout = timeout

    def get_postings(
        self,
        role: Literal["internship", "newgrad"] = "internship",
        timeframe: Literal["lastday", "lastweek", "lastmonth"] = "lastday",
        location: str | None = None,
    ) -> list[JobPosting]:
        """Fetch job postings by invoking the swelist CLI and parsing its output."""
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
        return list(unique.values())

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
