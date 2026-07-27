from __future__ import annotations

from collections.abc import Callable
from typing import Any
from urllib.parse import quote

import requests
from fastapi import APIRouter, Depends, HTTPException, Query, status
from starlette.background import BackgroundTask
from starlette.responses import StreamingResponse

from app.dependencies import get_student_session
from app.schemas.cms import (
    CmsCourseContentResponse,
    CmsCourseListResponse,
    CmsSearchResponse,
    CmsTranscriptResponse,
)
from app.sessions.models import StudentSession

router = APIRouter(prefix="/cms", tags=["CMS learning content"])


def _cms_call(
    callable_: Callable[[], Any],
    *,
    university_label: str = "University",
) -> Any:
    try:
        return callable_()
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from None
    except requests.HTTPError as exc:
        response = exc.response
        if response is not None and response.status_code in {401, 403}:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=(
                    f"{university_label} CMS rejected this session. "
                    "Sign out and sign in "
                    "again with your university account."
                ),
            ) from None
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=(
                f"{university_label} CMS could not return this content "
                "right now."
            ),
        ) from None
    except (requests.RequestException, RuntimeError):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"{university_label} CMS is temporarily unavailable.",
        ) from None


@router.get("/courses", response_model=CmsCourseListResponse)
def courses(
    refresh: bool = Query(default=False),
    season: str | None = Query(default=None, max_length=80),
    student: StudentSession = Depends(get_student_session),
) -> dict:
    selected = season or student.academic.current_season
    return _cms_call(
        lambda: student.cms.list_courses(
            force=refresh,
            season=selected,
        ),
        university_label=student.university_label,
    )


@router.get(
    "/courses/{course}/content",
    response_model=CmsCourseContentResponse,
)
def course_content(
    course: str,
    student: StudentSession = Depends(get_student_session),
) -> dict:
    return _cms_call(
        lambda: student.cms.course_content(course),
        university_label=student.university_label,
    )


@router.get("/search", response_model=CmsSearchResponse)
def search(
    query: str = Query(min_length=1, max_length=160),
    course_id: str | None = Query(default=None, max_length=120),
    student: StudentSession = Depends(get_student_session),
) -> dict:
    return _cms_call(
        lambda: student.cms.search(query, course_id=course_id),
        university_label=student.university_label,
    )


@router.get(
    "/items/{video_id}/transcript",
    response_model=CmsTranscriptResponse,
)
def transcript(
    video_id: str,
    student: StudentSession = Depends(get_student_session),
) -> dict:
    return _cms_call(
        lambda: student.cms.video_transcript(video_id),
        university_label=student.university_label,
    )


@router.get("/resources/{resource_id}/download")
def download_resource(
    resource_id: str,
    student: StudentSession = Depends(get_student_session),
) -> StreamingResponse:
    download = _cms_call(
        lambda: student.cms.client.open_resource(resource_id),
        university_label=student.university_label,
    )

    def body():
        for chunk in download.response.iter_content(chunk_size=1024 * 128):
            if chunk:
                yield chunk

    encoded_name = quote(download.filename)
    headers = {
        "Content-Disposition": (
            f"attachment; filename*=UTF-8''{encoded_name}"
        ),
        "X-Content-Type-Options": "nosniff",
    }
    content_length = download.response.headers.get("Content-Length")
    if content_length:
        headers["Content-Length"] = content_length
    return StreamingResponse(
        body(),
        media_type=download.content_type,
        headers=headers,
        background=BackgroundTask(download.response.close),
    )
