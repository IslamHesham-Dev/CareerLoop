from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from app.cms_live import GiuCmsClient


def _normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.casefold()).strip()


class SupplementalVideoCatalog:
    """The five approved Drive collections, never the CMS course catalog."""

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
    def _summary(course: dict[str, Any]) -> dict[str, Any]:
        return {
            "slug": course["slug"],
            "catalog_code": course["catalog_code"],
            "title": course["title"],
            "aliases": course["aliases"],
            "source_folders": course["source_folders"],
            "video_count": len(course["items"]),
            "transcribed_count": sum(
                item["transcript_status"] == "available"
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
        return self._summary(course), list(course["items"])

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

    def list_courses(self, *, force: bool = False) -> dict[str, Any]:
        courses = [
            self._merge_summary(course)
            for course in self.client.list_courses(force=force)
        ]
        return {
            "source": "GIU CMS",
            "status": "live",
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


supplemental_video_catalog = SupplementalVideoCatalog()
