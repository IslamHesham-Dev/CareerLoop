from __future__ import annotations

import re
import time
import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from fastapi.concurrency import run_in_threadpool

from app.application_service import (
    ApplicationIntakeError,
    generate_application_draft,
    linkedin_post_text,
)
from app.config import Settings, get_settings
from app.dependencies import get_student_session
from app.gmail import GmailClient, GmailIntegrationError
from app.schemas.applications import (
    ApplicationDraftResponse,
    ApplicationPreviewRequest,
    ApplicationSendResponse,
)
from app.sessions.models import StudentSession

router = APIRouter(
    prefix="/career/applications",
    tags=["career applications"],
)

MAX_CV_BYTES = 10 * 1024 * 1024
MAX_PENDING_DRAFTS = 5


@router.post("/preview", response_model=ApplicationDraftResponse)
async def preview_application(
    payload: ApplicationPreviewRequest,
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> ApplicationDraftResponse:
    try:
        post_text, source, warnings = await run_in_threadpool(
            linkedin_post_text,
            str(payload.linkedin_post_url),
            supplied_text=payload.post_text,
        )
    except ApplicationIntakeError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from None

    draft = await run_in_threadpool(
        generate_application_draft,
        post_text=post_text,
        candidate_name=_candidate_name(student),
        linkedin_profile=student.linkedin_profile,
        github_profile=student.github_profile,
        settings=settings,
        resume_profile=student.resume_profile,
    )
    recipient = _prototype_recipient(settings)
    if draft.detected_contact_email:
        warnings.append(
            "CareerLoop detected a contact email in the post, but this "
            "prototype is locked to the test recipient."
        )
    if (
        not student.linkedin_profile
        and not student.github_profile
        and not student.resume_profile
    ):
        warnings.append(
            "No LinkedIn or GitHub profile evidence was connected, so the "
            "draft intentionally avoids detailed personal claims."
        )

    draft_id = uuid.uuid4().hex
    stored = {
        "id": draft_id,
        "linkedin_post_url": str(payload.linkedin_post_url),
        "content_source": source,
        "post_excerpt": post_text[:600],
        "role": draft.role,
        "company": draft.company,
        "contact_name": draft.contact_name,
        "detected_contact_email": draft.detected_contact_email,
        "recipient": recipient,
        "subject": draft.subject,
        "body": draft.body,
        "warnings": warnings,
        "created_at": time.time(),
    }
    student.pending_application_drafts[draft_id] = stored
    _trim_pending_drafts(student)
    return ApplicationDraftResponse(
        **stored,
        prototype_recipient_locked=True,
        sender_email=student.gmail_email,
        gmail_connected=bool(
            student.gmail_access_token and student.gmail_email
        ),
    )


@router.post("/send", response_model=ApplicationSendResponse)
async def send_application(
    application_id: str = Form(..., min_length=16, max_length=64),
    subject: str = Form(..., min_length=3, max_length=180),
    body: str = Form(..., min_length=20, max_length=5000),
    cv: UploadFile = File(...),
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> ApplicationSendResponse:
    draft = student.pending_application_drafts.get(application_id)
    if draft is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "This application review expired or was already sent. "
                "Analyze the LinkedIn post again."
            ),
        )
    if not student.gmail_access_token or not student.gmail_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Connect Gmail before approving this application.",
        )

    safe_subject = _safe_subject(subject)
    clean_body = body.strip()
    file_name = cv.filename or "Current_CV.pdf"
    if not file_name.casefold().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Attach your current CV as a PDF.",
        )
    content = await cv.read(MAX_CV_BYTES + 1)
    await cv.close()
    if not content.startswith(b"%PDF"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="The selected CV is not a valid PDF.",
        )
    if len(content) > MAX_CV_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Choose a CV that is 10 MB or smaller.",
        )

    access_token = await _valid_access_token(student, settings)
    recipient = _prototype_recipient(settings)
    try:
        result = await run_in_threadpool(
            GmailClient.send_pdf,
            access_token=access_token,
            sender=student.gmail_email,
            recipient=recipient,
            subject=safe_subject,
            body=clean_body,
            attachment=content,
            attachment_name=_safe_pdf_name(file_name),
        )
    except GmailIntegrationError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None

    # A reviewed draft is one-time-use. Delete it only after Gmail confirms
    # the send and returns a message ID.
    del student.pending_application_drafts[application_id]
    return ApplicationSendResponse(
        message_id=str(result["id"]),
        thread_id=(
            str(result["threadId"]) if result.get("threadId") else None
        ),
        sender=student.gmail_email,
        recipient=recipient,
        subject=safe_subject,
        attachment_name=_safe_pdf_name(file_name),
        sent_at=datetime.now(timezone.utc),
    )


async def _valid_access_token(
    student: StudentSession,
    settings: Settings,
) -> str:
    token = student.gmail_access_token
    expires_at = student.gmail_token_expires_at
    if token and (expires_at is None or expires_at > time.time() + 60):
        return token
    if not student.gmail_refresh_token:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Your Gmail connection expired. Connect Gmail again.",
        )
    try:
        result = await run_in_threadpool(
            GmailClient.refresh_access_token,
            client_id=settings.google_oauth_client_id,
            client_secret=(
                settings.google_oauth_client_secret.get_secret_value()
            ),
            refresh_token=student.gmail_refresh_token,
        )
    except GmailIntegrationError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Reconnect Gmail before sending: {exc}",
        ) from None
    refreshed = result.get("access_token")
    if not isinstance(refreshed, str) or not refreshed:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Reconnect Gmail before sending.",
        )
    student.gmail_access_token = refreshed
    expires_in = result.get("expires_in")
    student.gmail_token_expires_at = (
        time.time() + float(expires_in)
        if isinstance(expires_in, (int, float))
        else None
    )
    return refreshed


def _candidate_name(student: StudentSession) -> str:
    for profile in (
        student.resume_profile,
        student.linkedin_profile,
        student.github_profile,
    ):
        if profile:
            name = profile.get("name")
            if isinstance(name, str) and 2 <= len(name.strip()) <= 100:
                return name.strip()
    return "Candidate"


def _prototype_recipient(settings: Settings) -> str:
    value = settings.prototype_application_recipient.strip().casefold()
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", value):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="The prototype application recipient is misconfigured.",
        )
    return value


def _safe_subject(value: str) -> str:
    clean = re.sub(r"[\r\n]+", " ", value).strip()
    if len(clean) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Add a subject before sending.",
        )
    return clean[:180]


def _safe_pdf_name(value: str) -> str:
    stem = re.sub(r"[^A-Za-z0-9._ -]+", "_", value).strip(" .")
    if not stem.casefold().endswith(".pdf"):
        stem = f"{stem}.pdf"
    return stem[:120] or "Current_CV.pdf"


def _trim_pending_drafts(student: StudentSession) -> None:
    if len(student.pending_application_drafts) <= MAX_PENDING_DRAFTS:
        return
    ordered = sorted(
        student.pending_application_drafts.items(),
        key=lambda item: float(item[1].get("created_at", 0)),
    )
    for key, _ in ordered[:-MAX_PENDING_DRAFTS]:
        student.pending_application_drafts.pop(key, None)
