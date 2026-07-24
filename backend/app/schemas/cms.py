from __future__ import annotations

from pydantic import BaseModel


class SourceFolderResponse(BaseModel):
    label: str
    kind: str
    url: str


class CmsCourseResponse(BaseModel):
    slug: str
    catalog_code: str
    official_course_code: str | None
    title: str
    aliases: list[str]
    description: str
    source_folders: list[SourceFolderResponse]
    content_counts: dict[str, int]
    video_count: int
    transcribed_count: int


class CmsCourseListResponse(BaseModel):
    source: str
    courses: list[CmsCourseResponse]


class CmsContentItemResponse(BaseModel):
    id: str
    title: str
    content_type: str
    media_type: str
    mime_type: str
    size_bytes: int | None
    drive_url: str
    collection: str
    transcript_status: str
    transcript_file: str | None
    summary_status: str
    sort_index: int


class CmsCourseContentResponse(BaseModel):
    course: CmsCourseResponse
    content_type: str
    items: list[CmsContentItemResponse]


class CmsSearchItemResponse(CmsContentItemResponse):
    course_slug: str
    course_title: str


class CmsSearchResponse(BaseModel):
    query: str
    matches: list[CmsSearchItemResponse]


class CmsTranscriptResponse(BaseModel):
    video_id: str
    course: str
    title: str
    status: str
    transcript: str | None
    message: str | None = None
