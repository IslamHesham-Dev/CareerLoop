from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool

from app.dependencies import get_student_session
from app.linkedin_pdf import (
    MAX_LINKEDIN_PDF_BYTES,
    LinkedInPdfError,
    extract_linkedin_profile,
)
from app.schemas.career import (
    LinkedInProfile,
    LinkedInProfileMessage,
    LinkedInProfileStatus,
)
from app.sessions.models import StudentSession

router = APIRouter(prefix="/career", tags=["career evidence"])


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


def _replace_profile(
    student: StudentSession,
    profile: LinkedInProfile | None,
) -> None:
    with student.chat_lock:
        student.linkedin_profile = profile.model_dump() if profile else None
        student.conversation.clear()
        student.agent = None
