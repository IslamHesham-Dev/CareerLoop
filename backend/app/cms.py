from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class CmsService:
    """Read-only CareerLoop CMS catalog backed by inventoried Drive videos."""

    def __init__(self, catalog_path: Path | None = None) -> None:
        backend_root = Path(__file__).resolve().parent.parent
        self.catalog_path = (
            catalog_path or backend_root / "content" / "cms_catalog.json"
        )
        self.transcript_dir = backend_root / "content" / "transcripts"
        self._catalog = json.loads(
            self.catalog_path.read_text(encoding="utf-8")
        )

    @staticmethod
    def _course_summary(course: dict[str, Any]) -> dict[str, Any]:
        items = course["items"]
        counts: dict[str, int] = {}
        for item in items:
            kind = item["content_type"]
            counts[kind] = counts.get(kind, 0) + 1
        return {
            "slug": course["slug"],
            "catalog_code": course["catalog_code"],
            "official_course_code": course["official_course_code"],
            "title": course["title"],
            "aliases": course["aliases"],
            "description": course["description"],
            "source_folders": course["source_folders"],
            "content_counts": counts,
            "video_count": len(items),
            "transcribed_count": sum(
                item["transcript_status"] == "available" for item in items
            ),
        }

    def list_courses(self) -> dict[str, Any]:
        return {
            "source": "CareerLoop CMS + Google Drive",
            "courses": [
                self._course_summary(course)
                for course in self._catalog["courses"]
            ],
        }

    def _find_course(self, query: str) -> dict[str, Any]:
        needle = query.strip().casefold()
        exact: list[dict[str, Any]] = []
        partial: list[dict[str, Any]] = []
        for course in self._catalog["courses"]:
            names = [
                course["slug"],
                course["catalog_code"],
                course["title"],
                *course["aliases"],
            ]
            folded = [name.casefold() for name in names if name]
            if needle in folded:
                exact.append(course)
            elif any(needle in name for name in folded):
                partial.append(course)
        matches = exact or partial
        if not matches:
            raise ValueError(f"No CMS course matches {query!r}.")
        if len(matches) > 1:
            raise ValueError(
                f"Ambiguous CMS course {query!r}; matches: "
                f"{[course['title'] for course in matches]}"
            )
        return matches[0]

    def course_content(
        self,
        course: str,
        content_type: str | None = None,
    ) -> dict[str, Any]:
        match = self._find_course(course)
        requested_type = (content_type or "").strip().casefold()
        items = match["items"]
        if requested_type and requested_type != "all":
            items = [
                item
                for item in items
                if item["content_type"].casefold() == requested_type
            ]
        return {
            "course": self._course_summary(match),
            "content_type": requested_type or "all",
            "items": items,
        }

    def search(
        self,
        query: str,
        *,
        course: str | None = None,
        limit: int = 50,
    ) -> dict[str, Any]:
        needle = query.strip().casefold()
        courses = (
            [self._find_course(course)]
            if course and course.strip()
            else self._catalog["courses"]
        )
        matches = [
            {
                "course_slug": candidate["slug"],
                "course_title": candidate["title"],
                **item,
            }
            for candidate in courses
            for item in candidate["items"]
            if needle in item["title"].casefold()
        ][:limit]
        return {"query": query, "matches": matches}

    def video_transcript(self, video_id: str) -> dict[str, Any]:
        for course in self._catalog["courses"]:
            for item in course["items"]:
                if item["id"] != video_id:
                    continue
                transcript_path = self.transcript_dir / f"{video_id}.md"
                if not transcript_path.exists():
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
                return {
                    "video_id": video_id,
                    "course": course["title"],
                    "title": item["title"],
                    "status": "available",
                    "transcript": transcript_path.read_text(
                        encoding="utf-8"
                    ),
                }
        raise ValueError(f"No CMS video matches ID {video_id!r}.")


cms_service = CmsService()
