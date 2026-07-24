from __future__ import annotations

import requests
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool

from guc_portal import GucPortal

from app.cms import CmsService
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

    # One university sign-in establishes both authenticated services. Validate
    # CMS now so the app never creates a portal-only session that fails later
    # when the student opens Courses.
    cms = CmsService(GiuCmsClient(username, password))
    try:
        await run_in_threadpool(
            lambda: cms.client.list_courses(force=True)
        )
    except requests.HTTPError as exc:
        cms.close()
        portal.session.auth = None
        portal.session.close()
        response = exc.response
        if response is not None and response.status_code in {401, 403}:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=(
                    "The portal accepted this account, but GIU CMS did not. "
                    "Use the same university username and password you use "
                    "when opening CMS in your browser."
                ),
            ) from None
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "The portal signed in, but GIU CMS is temporarily "
                "unavailable. No partial session was created."
            ),
        ) from None
    except Exception:
        cms.close()
        portal.session.auth = None
        portal.session.close()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "The university account was accepted, but the CMS course "
                "workspace could not be initialized."
            ),
        ) from None
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
        cms_connected=True,
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
        cms_connected=True,
    )


@router.post("/logout", response_model=MessageResponse)
def logout(token: str = Depends(get_access_token)) -> MessageResponse:
    session_store.delete(token)
    return MessageResponse(message="Signed out securely.")
