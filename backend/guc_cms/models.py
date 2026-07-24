"""Plain data holders for what the CMS gives back.

These are dataclasses on purpose. They carry no logic, they are easy to print,
and they turn into a dict with one line (`dataclasses.asdict`). That last part
matters later: when we expose the CMS to an agent, a tool has to return JSON,
and a dataclass is one step away from that.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Course:
    """One course row from the "all courses" page."""

    id: int
    season_id: int
    name: str  # full label as the CMS shows it
    code: str | None  # e.g. "CSEN603", None for things like an orientation
    title: str  # the name cleaned up: no code, no trailing id
    active: bool

    @property
    def path(self) -> str:
        """The CMS path for this course's own page."""
        return f"/apps/student/CourseViewStn.aspx?id={self.id}&sid={self.season_id}"


@dataclass
class ContentItem:
    """One downloadable thing inside a course (a PDF, a slide deck, a zip)."""

    content_id: int
    title: str  # e.g. "1 - Final Exam Sample 2023"
    kind: str | None  # e.g. "Lecture", "Assignment", "Exam"
    url: str  # download path on the server, e.g. "/Uploads/65/436/.../file.pdf"
    week: str | None  # which week block it sat under

    @property
    def filename(self) -> str:
        """The file name at the end of the download URL."""
        return self.url.rsplit("/", 1)[-1]


@dataclass
class CourseContent:
    """Everything on a single course page: the course, plus its files."""

    course_name: str
    season_name: str | None
    items: list[ContentItem]

    def weeks(self) -> dict[str, list[ContentItem]]:
        """Group the files by their week label, in the order they appear."""
        out: dict[str, list[ContentItem]] = {}
        for item in self.items:
            out.setdefault(item.week or "Unsorted", []).append(item)
        return out
