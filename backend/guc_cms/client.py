"""The one object you talk to: `GucCms`.

It holds a logged-in session and gives you three things:

    cms.list_courses()                 -> list[Course]
    cms.get_content(course)            -> CourseContent (files, grouped by week)
    cms.download(item, "downloads/")   -> Path to the saved file

Everything above returns plain data (dataclasses), which is exactly what you
want when you wrap these calls as agent tools later: a tool has to hand back
JSON, and a dataclass is one `asdict` away from that.
"""

from __future__ import annotations

import os
from pathlib import Path

import requests
from requests_ntlm import HttpNtlmAuth

from ._parse import parse_course_content, parse_courses
from ._sites import CMS_SITES
from .models import ContentItem, Course, CourseContent

BASE_URL = "https://cms.guc.edu.eg"  # kept for backward compatibility (GUC)


class GucCms:
    """A logged-in connection to a student CMS (GUC or GIU).

    The CMS uses Windows (NTLM) auth, the same login your browser pops up for.
    `requests_ntlm` does that handshake for us, so from here on it is just HTTP.

    Pick which university with `site="guc"` (default) or `site="giu"`, or set the
    GUC_SITE environment variable. GUC is verified; GIU is a starting point.

    Credentials come from the arguments, or from the GUC_USERNAME / GUC_PASSWORD
    environment variables if you leave them out. Never hard-code them in a file
    you might share.
    """

    def __init__(
        self,
        username: str | None = None,
        password: str | None = None,
        *,
        site: str | None = None,
        base_url: str | None = None,
        verify: bool = True,
        timeout: int = 30,
    ) -> None:
        username = username or os.environ.get("GUC_USERNAME")
        password = password or os.environ.get("GUC_PASSWORD")
        if not username or not password:
            raise ValueError(
                "Missing credentials: pass username/password, or set "
                "GUC_USERNAME and GUC_PASSWORD in your environment."
            )
        site = (site or os.environ.get("GUC_SITE") or "guc").lower()
        if site not in CMS_SITES:
            raise ValueError(f"Unknown site {site!r}. Known sites: {list(CMS_SITES)}.")
        self.site = CMS_SITES[site]
        self.base_url = (base_url or self.site.base_url).rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()
        self.session.auth = HttpNtlmAuth(username, password)
        self.session.verify = verify

    # -- low level ---------------------------------------------------------

    def _get(self, path: str, **params) -> requests.Response:
        """GET a CMS path and fail loudly if the server said no."""
        response = self.session.get(
            self.base_url + path, params=params or None, timeout=self.timeout
        )
        response.raise_for_status()
        return response

    def absolute_url(self, path: str) -> str:
        """Turn a "/Uploads/..." path into a full https URL."""
        if path.startswith("http"):
            return path
        return self.base_url + path

    # -- the useful three --------------------------------------------------

    def list_courses(self) -> list[Course]:
        """All courses the logged-in student is registered in."""
        html = self._get(self.site.course_list_path).text
        return parse_courses(html)

    def find_course(self, query: str) -> Course | None:
        """First course whose code or name matches `query` (case-insensitive)."""
        needle = query.strip().lower()
        for course in self.list_courses():
            haystack = f"{course.code or ''} {course.name}".lower()
            if needle in haystack:
                return course
        return None

    def get_content(self, course: Course | int, season_id: int | None = None) -> CourseContent:
        """The files on one course page, grouped by week.

        Pass a Course (from list_courses), or an id plus a season_id.
        """
        if isinstance(course, Course):
            course_id, season_id = course.id, course.season_id
        else:
            course_id = course
            if season_id is None:
                raise ValueError("Pass a Course, or both a course id and a season_id.")
        html = self._get(
            self.site.course_view_path, id=course_id, sid=season_id
        ).text
        return parse_course_content(html)

    def fetch_bytes(self, item: ContentItem | str) -> bytes:
        """Return a file's raw bytes without saving it anywhere.

        Use this when you want to read a file's content straight into memory,
        for example to convert it to text and hand it to a model. Nothing
        touches the disk.
        """
        url = item.url if isinstance(item, ContentItem) else item
        response = self.session.get(self.absolute_url(url), timeout=self.timeout)
        response.raise_for_status()
        return response.content

    def download(self, item: ContentItem | str, dest_dir: str | Path = ".") -> Path:
        """Save one file to `dest_dir` and return where it landed."""
        url = item.url if isinstance(item, ContentItem) else item
        dest_dir = Path(dest_dir)
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / url.rsplit("/", 1)[-1]

        with self.session.get(
            self.absolute_url(url), stream=True, timeout=self.timeout
        ) as response:
            response.raise_for_status()
            with open(dest, "wb") as handle:
                for chunk in response.iter_content(chunk_size=8192):
                    handle.write(chunk)
        return dest
