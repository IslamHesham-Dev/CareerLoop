from __future__ import annotations

import importlib.util
import time

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.dependencies import get_student_session
from app.github_profile import (
    GithubConfigurationError,
    GithubConnectionError,
    GithubDeviceClient,
    extract_github_profile,
)
from app.linkedin_pdf import (
    MAX_LINKEDIN_PDF_BYTES,
    LinkedInPdfError,
    extract_linkedin_profile,
)
from app.opportunities import OpportunityService
from app.schemas.career import (
    OpportunityPreferences,
    OpportunitySearchRequest,
    OpportunitySearchResponse,
    OpportunityStatusResponse,
    LinkedInProfile,
    LinkedInProfileMessage,
    LinkedInProfileStatus,
    GithubAuthorizationPoll,
    GithubDeviceAuthorization,
    GithubProfileEvidence,
    GithubProfileMessage,
    GithubProfileStatus,
)
from app.sessions.models import StudentSession

router = APIRouter(prefix="/career", tags=["career evidence"])
opportunity_service = OpportunityService()


@router.get(
    "/linkedin-profile",
    response_model=LinkedInProfileStatus,
)
def linkedin_profile_status(
    student: StudentSession = Depends(get_student_session),
) -> LinkedInProfileStatus:
    profile = (
        LinkedInProfile.model_validate(student.linkedin_profile)
        if student.linkedin_profile
        else None
    )
    return LinkedInProfileStatus(connected=profile is not None, profile=profile)


@router.post(
    "/linkedin-profile/import",
    response_model=LinkedInProfileStatus,
)
async def import_linkedin_profile(
    file: UploadFile = File(...),
    student: StudentSession = Depends(get_student_session),
) -> LinkedInProfileStatus:
    file_name = file.filename or "LinkedIn_Profile.pdf"
    if not file_name.casefold().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Choose the PDF exported from your LinkedIn profile.",
        )
    content = await file.read(MAX_LINKEDIN_PDF_BYTES + 1)
    await file.close()
    try:
        profile = await run_in_threadpool(
            extract_linkedin_profile,
            content,
            file_name=file_name,
        )
    except LinkedInPdfError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from None
    _replace_profile(student, profile)
    return LinkedInProfileStatus(connected=True, profile=profile)


@router.post(
    "/linkedin-profile/sync",
    response_model=LinkedInProfileStatus,
)
def sync_linkedin_profile(
    profile: LinkedInProfile,
    student: StudentSession = Depends(get_student_session),
) -> LinkedInProfileStatus:
    _replace_profile(student, profile)
    return LinkedInProfileStatus(connected=True, profile=profile)


@router.post(
    "/linkedin-profile/remove",
    response_model=LinkedInProfileMessage,
)
def remove_linkedin_profile(
    student: StudentSession = Depends(get_student_session),
) -> LinkedInProfileMessage:
    _replace_profile(student, None)
    return LinkedInProfileMessage(message="LinkedIn PDF profile removed.")


@router.get(
    "/github-profile",
    response_model=GithubProfileStatus,
)
def github_profile_status(
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> GithubProfileStatus:
    profile = (
        GithubProfileEvidence.model_validate(student.github_profile)
        if student.github_profile
        else None
    )
    configured = bool(settings.github_oauth_client_id.strip())
    return GithubProfileStatus(
        configured=configured,
        connected=profile is not None,
        profile=profile,
        message=(
            None
            if configured
            else "Add GITHUB_OAUTH_CLIENT_ID to enable GitHub connection."
        ),
    )


@router.post(
    "/github/connect/start",
    response_model=GithubDeviceAuthorization,
)
async def start_github_connection(
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> GithubDeviceAuthorization:
    try:
        payload = await run_in_threadpool(
            GithubDeviceClient(settings.github_oauth_client_id).start
        )
    except GithubConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None
    except (GithubConnectionError, OSError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None
    with student.chat_lock:
        student.github_device_code = str(payload["device_code"])
        student.github_device_expires_at = (
            time.time() + int(payload["expires_in"])
        )
        student.github_poll_interval = max(5, int(payload["interval"]))
        student.github_last_poll_at = None
    return GithubDeviceAuthorization(
        user_code=str(payload["user_code"]),
        verification_uri=str(payload["verification_uri"]),
        expires_in=int(payload["expires_in"]),
        interval=student.github_poll_interval,
    )


@router.post(
    "/github/connect/poll",
    response_model=GithubAuthorizationPoll,
)
async def poll_github_connection(
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> GithubAuthorizationPoll:
    now = time.time()
    device_code = student.github_device_code
    expires_at = student.github_device_expires_at or 0
    interval = student.github_poll_interval
    if not device_code:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Start GitHub connection before checking authorization.",
        )
    if now >= expires_at:
        _clear_github_device_flow(student)
        return GithubAuthorizationPoll(
            status="expired",
            retry_after=interval,
            message="The GitHub code expired. Start the connection again.",
        )
    last_poll = student.github_last_poll_at or 0
    if now - last_poll < interval:
        return GithubAuthorizationPoll(
            status="pending",
            retry_after=max(1, int(interval - (now - last_poll))),
        )
    student.github_last_poll_at = now
    try:
        result = await run_in_threadpool(
            GithubDeviceClient(settings.github_oauth_client_id).poll,
            device_code,
        )
    except GithubConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None
    except (GithubConnectionError, OSError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None

    result_status = str(result["status"])
    if result_status == "connected":
        access_token = str(result["access_token"])
        try:
            profile = await run_in_threadpool(
                extract_github_profile,
                access_token,
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=(
                    "GitHub was authorized, but repository evidence could not "
                    f"be analyzed: {exc}"
                ),
            ) from None
        with student.chat_lock:
            student.github_access_token = access_token
            _replace_github_profile(student, profile)
            _clear_github_device_flow(student)
        return GithubAuthorizationPoll(
            status="connected",
            retry_after=interval,
            profile=profile,
        )
    if result_status in {"expired", "denied"}:
        _clear_github_device_flow(student)
    if result_status == "slow_down":
        with student.chat_lock:
            student.github_poll_interval += 5
            interval = student.github_poll_interval
    return GithubAuthorizationPoll(
        status=result_status,  # type: ignore[arg-type]
        retry_after=interval,
        message=result.get("message"),
    )


@router.post(
    "/github-profile/sync",
    response_model=GithubProfileStatus,
)
def sync_github_profile(
    profile: GithubProfileEvidence,
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> GithubProfileStatus:
    _replace_github_profile(student, profile)
    return GithubProfileStatus(
        configured=bool(settings.github_oauth_client_id.strip()),
        connected=True,
        profile=profile,
    )


@router.post(
    "/github-profile/refresh",
    response_model=GithubProfileStatus,
)
async def refresh_github_profile(
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> GithubProfileStatus:
    if not student.github_access_token:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Reconnect GitHub to refresh this local profile snapshot."
            ),
        )
    try:
        profile = await run_in_threadpool(
            extract_github_profile,
            student.github_access_token,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"GitHub profile refresh failed: {exc}",
        ) from None
    _replace_github_profile(student, profile)
    return GithubProfileStatus(
        configured=bool(settings.github_oauth_client_id.strip()),
        connected=True,
        profile=profile,
    )


@router.post(
    "/github-profile/remove",
    response_model=GithubProfileMessage,
)
def remove_github_profile(
    student: StudentSession = Depends(get_student_session),
) -> GithubProfileMessage:
    with student.chat_lock:
        student.github_access_token = None
        _clear_github_device_flow(student)
        _replace_github_profile(student, None)
    return GithubProfileMessage(message="GitHub profile removed.")


@router.get(
    "/opportunities/status",
    response_model=OpportunityStatusResponse,
)
def opportunity_status(
    student: StudentSession = Depends(get_student_session),
) -> OpportunityStatusResponse:
    preferences = (
        OpportunityPreferences.model_validate(student.career_preferences)
        if student.career_preferences
        else None
    )
    return OpportunityStatusResponse(
        source="Swelist",
        connected=importlib.util.find_spec("swelist") is not None,
        adzuna_connected=False,
        course_count=len(opportunity_service.catalog.courses),
        preferences=preferences,
    )


@router.post(
    "/opportunities/search",
    response_model=OpportunitySearchResponse,
)
async def search_opportunities(
    payload: OpportunitySearchRequest,
    student: StudentSession = Depends(get_student_session),
) -> dict:
    preferences = payload.model_dump(exclude={"limit"})
    with student.chat_lock:
        student.career_preferences = preferences

    def search() -> dict:
        try:
            transcript = student.academic.full_transcript()
        except Exception:
            transcript = None
        return opportunity_service.search(
            **preferences,
            transcript=transcript,
            linkedin_profile=student.linkedin_profile,
            github_profile=student.github_profile,
            limit=payload.limit,
        )

    try:
        return await run_in_threadpool(search)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None


def _replace_profile(
    student: StudentSession,
    profile: LinkedInProfile | None,
) -> None:
    with student.chat_lock:
        student.linkedin_profile = profile.model_dump() if profile else None
        student.conversation.clear()
        student.agent = None


def _replace_github_profile(
    student: StudentSession,
    profile: GithubProfileEvidence | None,
) -> None:
    student.github_profile = profile.model_dump() if profile else None
    student.conversation.clear()
    student.agent = None


def _clear_github_device_flow(student: StudentSession) -> None:
    student.github_device_code = None
    student.github_device_expires_at = None
    student.github_last_poll_at = None
