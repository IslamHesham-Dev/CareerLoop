from __future__ import annotations

import importlib.util
import io
import time

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import StreamingResponse

from app.career_documents import (
    CareerDocumentError,
    generate_document,
    public_document,
)
from app.config import Settings, get_settings
from cv_connector import CVExtractionError, extract_cv_profile_from_bytes
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
    ResumeProfile,
    ResumeProfileMessage,
    ResumeProfileStatus,
    ToneAnswers,
    ToneMessage,
    ToneStatus,
    GithubAuthorizationPoll,
    GithubDeviceAuthorization,
    GithubProfileEvidence,
    GithubProfileMessage,
    GithubProfileStatus,
    CareerDocumentGenerateRequest,
    CareerDocumentRefineRequest,
    CareerDocumentResponse,
    JobDocumentTarget,
)
from app.tone import ONBOARDING_QUESTIONS
from app.sessions.models import StudentSession

router = APIRouter(prefix="/career", tags=["career evidence"])
opportunity_service = OpportunityService()
MAX_RESUME_PDF_BYTES = 10 * 1024 * 1024


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


@router.get("/resume", response_model=ResumeProfileStatus)
def resume_profile_status(
    student: StudentSession = Depends(get_student_session),
) -> ResumeProfileStatus:
    profile = (
        ResumeProfile.model_validate(student.resume_profile)
        if student.resume_profile
        else None
    )
    return ResumeProfileStatus(connected=profile is not None, profile=profile)


@router.post("/resume/import", response_model=ResumeProfileStatus)
async def import_resume_profile(
    file: UploadFile = File(...),
    student: StudentSession = Depends(get_student_session),
) -> ResumeProfileStatus:
    file_name = file.filename or "Current_CV.pdf"
    if not file_name.casefold().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Choose your resume or CV as a PDF.",
        )
    content = await file.read(MAX_RESUME_PDF_BYTES + 1)
    await file.close()
    if len(content) > MAX_RESUME_PDF_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Choose a resume that is 10 MB or smaller.",
        )
    try:
        extracted = await run_in_threadpool(
            extract_cv_profile_from_bytes,
            content,
            file_name=file_name,
        )
        profile = ResumeProfile.model_validate(extracted.to_dict())
    except CVExtractionError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from None
    _replace_resume_profile(student, profile)
    return ResumeProfileStatus(connected=True, profile=profile)


@router.post("/resume/sync", response_model=ResumeProfileStatus)
def sync_resume_profile(
    profile: ResumeProfile,
    student: StudentSession = Depends(get_student_session),
) -> ResumeProfileStatus:
    _replace_resume_profile(student, profile)
    return ResumeProfileStatus(connected=True, profile=profile)


@router.post("/resume/remove", response_model=ResumeProfileMessage)
def remove_resume_profile(
    student: StudentSession = Depends(get_student_session),
) -> ResumeProfileMessage:
    _replace_resume_profile(student, None)
    return ResumeProfileMessage(message="Resume profile removed.")


@router.get("/tone/questions", response_model=list[str])
def tone_onboarding_questions() -> list[str]:
    """The fixed prompts the app should ask to elicit the student's voice."""
    return list(ONBOARDING_QUESTIONS)


@router.get("/tone", response_model=ToneStatus)
def tone_status(
    student: StudentSession = Depends(get_student_session),
) -> ToneStatus:
    answers = student.tone_profile or {}
    return ToneStatus(connected=bool(answers), answers=answers)


@router.post("/tone/sync", response_model=ToneStatus)
def sync_tone_answers(
    payload: ToneAnswers,
    student: StudentSession = Depends(get_student_session),
) -> ToneStatus:
    _replace_tone_profile(student, payload.answers or None)
    return ToneStatus(connected=bool(payload.answers), answers=payload.answers)


@router.post("/tone/remove", response_model=ToneMessage)
def remove_tone_answers(
    student: StudentSession = Depends(get_student_session),
) -> ToneMessage:
    _replace_tone_profile(student, None)
    return ToneMessage(message="Tone answers removed.")


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
            resume_profile=student.resume_profile,
            limit=payload.limit,
        )

    try:
        return await run_in_threadpool(search)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None


@router.post(
    "/documents/generate",
    response_model=CareerDocumentResponse,
)
async def generate_career_document(
    payload: CareerDocumentGenerateRequest,
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    try:
        record = await run_in_threadpool(
            generate_document,
            student=student,
            settings=settings,
            kind=payload.kind,
            job=payload.job,
            instructions=payload.instructions,
        )
    except CareerDocumentError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"The tailored document could not be generated: {exc}",
        ) from None
    return public_document(record)


@router.post(
    "/documents/{document_id}/refine",
    response_model=CareerDocumentResponse,
)
async def refine_career_document(
    document_id: str,
    payload: CareerDocumentRefineRequest,
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    existing = student.career_documents.get(document_id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This generated document is no longer in the active session.",
        )
    try:
        record = await run_in_threadpool(
            generate_document,
            student=student,
            settings=settings,
            kind=existing["kind"],
            job=JobDocumentTarget.model_validate(existing["job"]),
            instructions=payload.instruction,
            existing=existing,
        )
    except CareerDocumentError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"The document could not be refined: {exc}",
        ) from None
    return public_document(record)


@router.get("/documents/{document_id}/pdf")
def download_career_document(
    document_id: str,
    student: StudentSession = Depends(get_student_session),
) -> StreamingResponse:
    record = student.career_documents.get(document_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This generated document is no longer in the active session.",
        )
    return StreamingResponse(
        io.BytesIO(record["pdf_bytes"]),
        media_type="application/pdf",
        headers={
            "Cache-Control": "no-store",
            "Content-Disposition": (
                f'inline; filename="{record["filename"]}"'
            ),
            "Cache-Control": "private, no-store",
        },
    )


def _replace_profile(
    student: StudentSession,
    profile: LinkedInProfile | None,
) -> None:
    with student.chat_lock:
        student.linkedin_profile = profile.model_dump() if profile else None
        _clear_career_documents(student)
        student.conversation.clear()
        student.agent = None


def _replace_github_profile(
    student: StudentSession,
    profile: GithubProfileEvidence | None,
) -> None:
    student.github_profile = profile.model_dump() if profile else None
    _clear_career_documents(student)
    student.conversation.clear()
    student.agent = None


def _replace_resume_profile(
    student: StudentSession,
    profile: ResumeProfile | None,
) -> None:
    with student.chat_lock:
        student.resume_profile = profile.model_dump() if profile else None
        _clear_career_documents(student)
        student.conversation.clear()
        student.agent = None


def _replace_tone_profile(
    student: StudentSession,
    answers: dict[str, str] | None,
) -> None:
    with student.chat_lock:
        student.tone_profile = answers
        _clear_career_documents(student)
        student.conversation.clear()
        student.agent = None


def _clear_github_device_flow(student: StudentSession) -> None:
    student.github_device_code = None
    student.github_device_expires_at = None
    student.github_last_poll_at = None


def _clear_career_documents(student: StudentSession) -> None:
    documents = getattr(student, "career_documents", None)
    if documents is not None:
        documents.clear()
