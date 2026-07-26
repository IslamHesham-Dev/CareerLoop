from __future__ import annotations

from pydantic import BaseModel


class SourceFolderResponse(BaseModel):
    label: str
    kind: str
    url: str


class CmsCourseResponse(BaseModel):
    id: str
    code: str
    title: str
    cms_label: str
    resource_count: int | None = None
    season: str = ""
    season_id: int | None = None
    active: bool | None = None
    has_supplemental_videos: bool
    video_count: int
    transcribed_count: int


class CmsCourseListResponse(BaseModel):
    source: str
    status: str
    season: str
    courses: list[CmsCourseResponse]
    message: str | None = None


class CmsResourceResponse(BaseModel):
    id: str
    title: str
    subtitle: str
    content_type: str
    file_extension: str
    week: int | None
    week_label: str | None
    is_vod: bool
    download_path: str


class CmsVideoResponse(BaseModel):
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


class VideoCollectionResponse(BaseModel):
    slug: str
    catalog_code: str
    title: str
    aliases: list[str]
    source_folders: list[SourceFolderResponse]
    video_count: int
    transcribed_count: int


class CmsCourseContentResponse(BaseModel):
    course: CmsCourseResponse
    cms_resources: list[CmsResourceResponse]
    available_videos: list[CmsVideoResponse]
    video_collection: VideoCollectionResponse | None


class CmsSearchResponse(BaseModel):
    query: str
    matches: list[dict]


class CmsTranscriptResponse(BaseModel):
    video_id: str
    course: str
    title: str
    status: str
    transcript: str | None
    message: str | None = None
