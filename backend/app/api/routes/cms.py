from __future__ import annotations

from collections.abc import Callable
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.cms import cms_service
from app.dependencies import get_student_session
from app.schemas.cms import (
    CmsCourseContentResponse,
    CmsCourseListResponse,
    CmsSearchResponse,
    CmsTranscriptResponse,
)
from app.sessions.models import StudentSession

router = APIRouter(prefix="/cms", tags=["CMS learning content"])


def _cms_call(callable_: Callable[[], Any]) -> Any:
    try:
        return callable_()
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from None


@router.get("/courses", response_model=CmsCourseListResponse)
def courses(
    _student: StudentSession = Depends(get_student_session),
) -> dict:
    return cms_service.list_courses()


@router.get(
    "/courses/{course}/content",
    response_model=CmsCourseContentResponse,
)
def course_content(
    course: str,
    content_type: str | None = Query(default=None, max_length=40),
    _student: StudentSession = Depends(get_student_session),
) -> dict:
    return _cms_call(
        lambda: cms_service.course_content(course, content_type)
    )


@router.get("/search", response_model=CmsSearchResponse)
def search(
    query: str = Query(min_length=1, max_length=160),
    course: str | None = Query(default=None, max_length=120),
    _student: StudentSession = Depends(get_student_session),
) -> dict:
    return _cms_call(lambda: cms_service.search(query, course=course))


@router.get(
    "/items/{video_id}/transcript",
    response_model=CmsTranscriptResponse,
)
def transcript(
    video_id: str,
    _student: StudentSession = Depends(get_student_session),
) -> dict:
    return _cms_call(lambda: cms_service.video_transcript(video_id))
