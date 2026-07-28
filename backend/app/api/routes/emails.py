"""The explicit, human-confirmed send step for a drafted career email.

Drafting (app.agent.factory.draft_career_email) only ever creates a pending
entry in student.pending_email_drafts - it cannot send anything. This route
is the one place an email actually leaves the server, and it only fires
when the Flutter app calls it after the student has reviewed (and can edit)
the subject/body. Mirrors app/api/routes/applications.py's /send route.
"""

from __future__ import annotations

import re
import time
from datetime import datetime, timezone

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

from app.config import Settings, get_settings
from app.dependencies import get_student_session
from app.gmail import GmailClient, GmailIntegrationError
from app.schemas.emails import EmailSendResponse
from app.sessions.models import StudentSession

router = APIRouter(prefix="/career/emails", tags=["career emails"])

MAX_CV_BYTES = 10 * 1024 * 1024


@router.post("/{draft_id}/send", response_model=EmailSendResponse)
async def send_career_email(
    draft_id: str,
    subject: str = Form(..., min_length=3, max_length=200),
    body: str = Form(..., min_length=20, max_length=5000),
    cv: UploadFile | None = File(default=None),
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> EmailSendResponse:
    draft = student.pending_email_drafts.get(draft_id)
    if draft is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "This email draft expired or was already sent. Draft it "
                "again."
            ),
        )
    if not student.gmail_access_token or not student.gmail_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Connect Gmail before sending.",
        )

    recipient = draft["recipient_email"]
    safe_subject = _safe_subject(subject)
    clean_body = body.strip()
    if len(clean_body) < 20:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="The email body is too short.",
        )

    # A CV attachment is optional here - unlike the LinkedIn-application
    # flow, not every career email (a question to a professor, a short
    # recruiter introduction) needs one.
    attachment_bytes: bytes | None = None
    attachment_name: str | None = None
    if cv is not None:
        file_name = cv.filename or "Current_CV.pdf"
        if not file_name.casefold().endswith(".pdf"):
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail="Attach the CV as a PDF, or omit it.",
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
        attachment_bytes = content
        attachment_name = _safe_pdf_name(file_name)

    access_token = await _valid_access_token(student, settings)
    try:
        if attachment_bytes is not None:
            result = await run_in_threadpool(
                GmailClient.send_pdf,
                access_token=access_token,
                sender=student.gmail_email,
                recipient=recipient,
                subject=safe_subject,
                body=clean_body,
                attachment=attachment_bytes,
                attachment_name=attachment_name,
            )
        else:
            result = await run_in_threadpool(
                GmailClient.send,
                access_token=access_token,
                sender=student.gmail_email,
                recipient=recipient,
                subject=safe_subject,
                body=clean_body,
            )
    except GmailIntegrationError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None

    # A reviewed draft is one-time-use, same as the LinkedIn-application flow.
    del student.pending_email_drafts[draft_id]
    if student.last_email_draft_id == draft_id:
        student.last_email_draft_id = None

    return EmailSendResponse(
        message_id=str(result["id"]),
        thread_id=str(result["threadId"]) if result.get("threadId") else None,
        sender=student.gmail_email,
        recipient=recipient,
        subject=safe_subject,
        attachment_name=attachment_name,
        sent_at=datetime.now(timezone.utc),
    )


async def _valid_access_token(student: StudentSession, settings: Settings) -> str:
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


def _safe_subject(value: str) -> str:
    clean = re.sub(r"[\r\n]+", " ", value).strip()
    if len(clean) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Add a subject before sending.",
        )
    return clean[:200]


def _safe_pdf_name(value: str) -> str:
    stem = re.sub(r"[^A-Za-z0-9._ -]+", "_", value).strip(" .")
    if not stem.casefold().endswith(".pdf"):
        stem = f"{stem}.pdf"
    return stem[:120] or "Current_CV.pdf"
