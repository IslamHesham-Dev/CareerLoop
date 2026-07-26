from __future__ import annotations

import requests
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool

from guc_portal import GucPortal

from app.cms import CmsService, UnavailableCmsService
from app.cms_live import GiuCmsClient
from app.dependencies import get_access_token, get_student_session
from app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    MessageResponse,
    SessionResponse,
)
from app.sessions.models import StudentSession
from app.state import session_store

router = APIRouter(prefix="/auth", tags=["authentication"])

CMS_UNAVAILABLE_MESSAGE = (
    "GIU CMS is not available for this account right now. This commonly "
    "happens when final-year or graduate students no longer have active CMS "
    "course access. CareerLoop will continue to work with your portal grades, "
    "transcripts, semester history, and CareerLoop Copilot; only CMS materials "
    "and its course-linked videos are unavailable."
)


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest) -> LoginResponse:
    username = payload.username.strip()
    password = payload.password.get_secret_value()
    portal = GucPortal(
        username=username,
        password=password,
        site="giu",
    )
    try:
        seasons = await run_in_threadpool(
            lambda: portal.available_seasons(tries=1, delay=0)
        )
    except requests.HTTPError as exc:
        portal.session.auth = None
        portal.session.close()
        response = exc.response
        if response is not None and response.status_code in {401, 403}:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="GIU rejected the username or password.",
            ) from None
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="GIU portal is temporarily unavailable. Try again shortly.",
        ) from None
    except Exception:
        portal.session.auth = None
        portal.session.close()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Could not establish a GIU portal session.",
        ) from None

    # Portal authentication is the session requirement. CMS is optional because
    # final-year and graduate accounts may retain portal access after their CMS
    # course access has ended.
    live_cms = CmsService(GiuCmsClient(username, password))
    try:
        await run_in_threadpool(
            lambda: live_cms.client.list_courses(force=True)
        )
        cms: CmsService | UnavailableCmsService = live_cms
    except requests.RequestException:
        live_cms.close()
        cms = UnavailableCmsService(CMS_UNAVAILABLE_MESSAGE)
    except Exception:
        live_cms.close()
        cms = UnavailableCmsService(CMS_UNAVAILABLE_MESSAGE)
    try:
        token, student = session_store.create(
            portal,
            cms,
            enrollment_year=payload.enrollment_year,
            seasons=seasons,
        )
    except Exception:
        cms.close()
        portal.session.auth = None
        portal.session.close()
        raise
    # Use the newest non-empty transcript page inside the student's four-year
    # enrollment window to choose the advisory year and semester. If GIU is
    # temporarily flaky, login still succeeds with the configured fallback.
    try:
        await run_in_threadpool(student.academic.select_latest_actual_context)
    except Exception:
        pass
    return LoginResponse(
        access_token=token,
        expires_in_seconds=student.expires_in_seconds,
        current_season=student.academic.current_season,
        advisory_year=student.academic.advisory_year,
        enrollment_year=student.academic.enrollment_year,
        transcript_years=student.academic.transcript_window_years,
        cms_connected=cms.connected,
        cms_message=cms.unavailable_message,
    )


@router.get("/session", response_model=SessionResponse)
def session_status(
    student: StudentSession = Depends(get_student_session),
) -> SessionResponse:
    return SessionResponse(
        authenticated=True,
        expires_in_seconds=student.expires_in_seconds,
        current_season=student.academic.current_season,
        advisory_year=student.academic.advisory_year,
        enrollment_year=student.academic.enrollment_year,
        transcript_years=student.academic.transcript_window_years,
        cms_connected=student.cms.connected,
        cms_message=student.cms.unavailable_message,
    )


@router.post("/logout", response_model=MessageResponse)
def logout(token: str = Depends(get_access_token)) -> MessageResponse:
    session_store.delete(token)
    return MessageResponse(message="Signed out securely.")
