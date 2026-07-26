from __future__ import annotations

import json
import re
import threading
from io import BytesIO
from pathlib import Path
from typing import Any

from pypdf import PdfReader

from app.cms_live import GiuCmsClient


def _normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.casefold()).strip()


TRANSCRIPT_BLOCK = re.compile(
    r"<!-- TRANSCRIPT START: (?P<id>[^ ]+) -->\s*"
    r"(?P<text>.*?)\s*"
    r"<!-- TRANSCRIPT END: (?P=id) -->",
    re.DOTALL,
)
TRANSCRIPT_PLACEHOLDERS = {
    "[PASTE TRANSCRIPT OR DETAILED SUMMARY HERE]",
    "[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]",
}


class SupplementalVideoCatalog:
    """The five approved Drive collections, never the CMS course catalog."""

    def __init__(
        self,
        catalog_path: Path | None = None,
        *,
        transcript_dir: Path | None = None,
        intake_path: Path | None = None,
    ) -> None:
        backend_root = Path(__file__).resolve().parent.parent
        self.catalog_path = (
            catalog_path or backend_root / "content" / "cms_catalog.json"
        )
        self.transcript_dir = (
            transcript_dir or backend_root / "content" / "transcripts"
        )
        self.intake_path = (
            intake_path
            or backend_root / "content" / "transcript_intake_template.md"
        )
        self._catalog = json.loads(
            self.catalog_path.read_text(encoding="utf-8")
        )
        self._intake_cache_key: tuple[int, int] | None = None
        self._intake_cache: dict[str, str] = {}
        self._transcript_lock = threading.RLock()

    def _intake_transcripts(self) -> dict[str, str]:
        with self._transcript_lock:
            if not self.intake_path.exists():
                self._intake_cache_key = None
                self._intake_cache = {}
                return {}
            stat = self.intake_path.stat()
            cache_key = (stat.st_mtime_ns, stat.st_size)
            if cache_key != self._intake_cache_key:
                text = self.intake_path.read_text(encoding="utf-8")
                self._intake_cache = {
                    match.group("id"): content
                    for match in TRANSCRIPT_BLOCK.finditer(text)
                    if (
                        (content := match.group("text").strip())
                        and content not in TRANSCRIPT_PLACEHOLDERS
                    )
                }
                self._intake_cache_key = cache_key
            return dict(self._intake_cache)

    def _available_transcript_ids(self) -> set[str]:
        file_ids = (
            {
                path.stem
                for path in self.transcript_dir.glob("*.md")
                if path.is_file()
            }
            if self.transcript_dir.exists()
            else set()
        )
        return file_ids | set(self._intake_transcripts())

    def _transcript(self, video_id: str) -> tuple[str, str] | None:
        transcript_path = self.transcript_dir / f"{video_id}.md"
        if transcript_path.exists():
            return (
                transcript_path.read_text(encoding="utf-8"),
                f"transcripts/{video_id}.md",
            )
        intake = self._intake_transcripts().get(video_id)
        if intake:
            return (
                intake,
                f"transcript_intake_template.md#{video_id}",
            )
        return None

    def _summary(self, course: dict[str, Any]) -> dict[str, Any]:
        available = self._available_transcript_ids()
        return {
            "slug": course["slug"],
            "catalog_code": course["catalog_code"],
            "title": course["title"],
            "aliases": course["aliases"],
            "source_folders": course["source_folders"],
            "video_count": len(course["items"]),
            "transcribed_count": sum(
                item["id"] in available
                for item in course["items"]
            ),
        }

    @staticmethod
    def _names(course: dict[str, Any]) -> list[str]:
        return [
            course["title"],
            course["catalog_code"],
            course.get("official_course_code") or "",
            *course["aliases"],
        ]

    def match(
        self,
        *,
        code: str = "",
        title: str = "",
        label: str = "",
    ) -> dict[str, Any] | None:
        haystack = _normalized(" ".join((code, title, label)))
        if not haystack:
            return None
        exact_code = _normalized(code)
        for course in self._catalog["courses"]:
            official = _normalized(course.get("official_course_code") or "")
            if official and exact_code and official == exact_code:
                return course
            for name in self._names(course):
                needle = _normalized(name)
                if len(needle) >= 4 and needle in haystack:
                    return course
        return None

    def videos_for(
        self,
        *,
        code: str = "",
        title: str = "",
        label: str = "",
    ) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
        course = self.match(code=code, title=title, label=label)
        if course is None:
            return None, []
        available = self._available_transcript_ids()
        videos = []
        for item in course["items"]:
            video = dict(item)
            if item["id"] in available:
                video["transcript_status"] = "available"
                transcript_path = self.transcript_dir / f"{item['id']}.md"
                if transcript_path.exists():
                    video["transcript_file"] = f"transcripts/{item['id']}.md"
                elif not video.get("transcript_file"):
                    video["transcript_file"] = (
                        f"transcript_intake_template.md#{item['id']}"
                    )
            else:
                video["transcript_status"] = "pending"
                video["transcript_file"] = None
            videos.append(video)
        return self._summary(course), videos

    def video_transcript(self, video_id: str) -> dict[str, Any]:
        for course in self._catalog["courses"]:
            for item in course["items"]:
                if item["id"] != video_id:
                    continue
                transcript = self._transcript(video_id)
                if transcript is None:
                    return {
                        "video_id": video_id,
                        "course": course["title"],
                        "title": item["title"],
                        "status": "pending",
                        "transcript": None,
                        "message": (
                            "A transcript has not been supplied for this "
                            "video yet."
                        ),
                    }
                text, source = transcript
                return {
                    "video_id": video_id,
                    "course": course["title"],
                    "title": item["title"],
                    "status": "available",
                    "transcript": text,
                    "source": source,
                    "character_count": len(text),
                }
        raise ValueError(f"No supplemental video matches ID {video_id!r}.")


class CmsService:
    """Per-student view of live GIU CMS plus optional Drive videos."""

    def __init__(
        self,
        client: GiuCmsClient,
        supplemental: SupplementalVideoCatalog | None = None,
    ) -> None:
        self.client = client
        self.supplemental = supplemental or supplemental_video_catalog

    def close(self) -> None:
        self.client.close()

    def _merge_summary(self, course: dict[str, Any]) -> dict[str, Any]:
        supplement, videos = self.supplemental.videos_for(
            code=course.get("code", ""),
            title=course.get("title", ""),
            label=course.get("cms_label", ""),
        )
        return {
            **course,
            "has_supplemental_videos": bool(videos),
            "video_count": len(videos),
            "transcribed_count": (
                supplement["transcribed_count"] if supplement else 0
            ),
        }

    def list_courses(
        self,
        *,
        force: bool = False,
        season: str | None = None,
    ) -> dict[str, Any]:
        courses = [
            self._merge_summary(course)
            for course in self.client.list_courses(force=force)
        ]
        selected = (season or "").strip()
        if selected and selected.casefold() != "all":
            needle = _normalized(selected)
            courses = [
                course
                for course in courses
                if _normalized(course.get("season", "")) == needle
            ]
        return {
            "source": "GIU CMS",
            "status": "live",
            "season": selected or "all",
            "courses": courses,
        }

    def course_content(self, course_id: str) -> dict[str, Any]:
        live = self.client.course_content(course_id)
        supplement, videos = self.supplemental.videos_for(
            code=live.get("code", ""),
            title=live.get("title", ""),
            label=live.get("cms_label", ""),
        )
        course = self._merge_summary(live)
        return {
            "course": course,
            "cms_resources": live["resources"],
            "available_videos": videos,
            "video_collection": supplement,
        }

    def search(
        self,
        query: str,
        *,
        course_id: str | None = None,
        limit: int = 50,
    ) -> dict[str, Any]:
        needle = _normalized(query)
        if not needle:
            raise ValueError("A CMS search query is required.")
        courses = self.list_courses()["courses"]
        if course_id:
            courses = [
                course for course in courses if course["id"] == course_id
            ]
            if not courses:
                raise ValueError(f"No CMS course matches ID {course_id!r}.")

        matches: list[dict[str, Any]] = []
        for course in courses:
            if needle in _normalized(
                f"{course['code']} {course['title']} {course['cms_label']}"
            ):
                matches.append(
                    {
                        "kind": "course",
                        "course_id": course["id"],
                        "course_code": course["code"],
                        "course_title": course["title"],
                        "title": course["title"],
                    }
                )
            # Resource pages are loaded only for a requested course, avoiding
            # dozens of CMS requests for a broad search.
            if course_id:
                detail = self.course_content(course["id"])
                for resource in detail["cms_resources"]:
                    if needle in _normalized(
                        f"{resource['title']} {resource['subtitle']} "
                        f"{resource['content_type']}"
                    ):
                        matches.append(
                            {
                                "kind": "cms_resource",
                                "course_id": course["id"],
                                "course_code": course["code"],
                                "course_title": course["title"],
                                **resource,
                            }
                        )
                for video in detail["available_videos"]:
                    if needle in _normalized(video["title"]):
                        matches.append(
                            {
                                "kind": "supplemental_video",
                                "course_id": course["id"],
                                "course_code": course["code"],
                                "course_title": course["title"],
                                **video,
                            }
                        )
        return {"query": query, "matches": matches[:limit]}

    def video_transcript(self, video_id: str) -> dict[str, Any]:
        return self.supplemental.video_transcript(video_id)

    def resource_text(
        self,
        resource_id: str,
        *,
        max_chars: int = 60_000,
        max_pages: int = 80,
    ) -> dict[str, Any]:
        """Extract bounded text from an authenticated CMS PDF for the agent."""
        download = self.client.open_resource(resource_id)
        try:
            is_pdf = (
                "pdf" in download.content_type.casefold()
                or download.filename.casefold().endswith(".pdf")
            )
            if not is_pdf:
                raise ValueError(
                    "AI reading is currently available for CMS PDF files."
                )
            data = download.response.content
            if not data.startswith(b"%PDF"):
                raise RuntimeError(
                    "GIU CMS did not return a valid PDF document."
                )
            reader = PdfReader(BytesIO(data))
            page_count = len(reader.pages)
            pages = [
                page.extract_text() or ""
                for page in reader.pages[:max_pages]
            ]
            text = "\n\n".join(pages).strip()
            if not text:
                return {
                    "resource_id": resource_id,
                    "filename": download.filename,
                    "page_count": page_count,
                    "text": "",
                    "truncated": False,
                    "message": (
                        "The PDF contains no extractable text; it may be "
                        "scanned images."
                    ),
                }
            truncated = len(text) > max_chars or page_count > max_pages
            return {
                "resource_id": resource_id,
                "filename": download.filename,
                "page_count": page_count,
                "text": text[:max_chars],
                "truncated": truncated,
            }
        finally:
            download.response.close()


supplemental_video_catalog = SupplementalVideoCatalog()
