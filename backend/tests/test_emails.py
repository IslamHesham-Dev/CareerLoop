from __future__ import annotations

import asyncio
import base64
import io
import threading
import time
from email import policy
from email.parser import BytesParser
from types import SimpleNamespace

import pytest
from fastapi import HTTPException, UploadFile

from app.api.routes import emails
from app.config import Settings
from app.gmail import GmailClient
from app.schemas.emails import EmailDraftRequest
from email_generator.models import EmailDraftContent


def test_gmail_send_builds_plain_text_message_with_no_attachment(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    class Response:
        status_code = 200

        @staticmethod
        def json() -> dict[str, str]:
            return {"id": "message-1", "threadId": "thread-1"}

    def fake_post(*args, **kwargs):
        captured.update(kwargs)
        return Response()

    monkeypatch.setattr("app.gmail.requests.post", fake_post)
    result = GmailClient.send(
        access_token="access",
        sender="candidate@gmail.com",
        recipient="prof@giu-uni.de",
        subject="Recommendation letter request",
        body="Hello Professor, would you be willing to write me a letter?",
    )

    raw = captured["json"]["raw"]  # type: ignore[index]
    message = BytesParser(policy=policy.default).parsebytes(
        base64.urlsafe_b64decode(raw)
    )
    assert result["id"] == "message-1"
    assert message["To"] == "prof@giu-uni.de"
    assert list(message.iter_attachments()) == []


def _fake_student(**overrides) -> SimpleNamespace:
    defaults = dict(
        pending_email_drafts={
            "draft-1": {
                "id": "draft-1",
                "recipient_email": "prof@giu-uni.de",
                "purpose": "ask for a recommendation letter",
                "subject": "Recommendation letter request",
                "body": "Hello Professor, would you write me a letter?",
                "sources_used": [],
                "created_at": "2026-01-01T00:00:00",
            }
        },
        last_email_draft_id="draft-1",
        gmail_access_token="access",
        gmail_refresh_token="refresh",
        gmail_token_expires_at=time.time() + 3600,
        gmail_email="candidate@gmail.com",
    )
    defaults.update(overrides)
    return SimpleNamespace(**defaults)


def test_send_career_email_without_attachment_uses_plain_send(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    def fake_send(**kwargs):
        captured.update(kwargs)
        return {"id": "message-2", "threadId": "thread-2"}

    monkeypatch.setattr(emails.GmailClient, "send", staticmethod(fake_send))
    student = _fake_student()

    response = asyncio.run(
        emails.send_career_email(
            draft_id="draft-1",
            subject="Recommendation letter request",
            body="Hello Professor, would you write me a letter?",
            cv=None,
            student=student,
            settings=Settings(),
        )
    )

    assert captured["recipient"] == "prof@giu-uni.de"
    assert response.message_id == "message-2"
    assert response.attachment_name is None
    assert "draft-1" not in student.pending_email_drafts
    assert student.last_email_draft_id is None


def test_send_career_email_with_pdf_attachment_uses_send_pdf(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    def fake_send_pdf(**kwargs):
        captured.update(kwargs)
        return {"id": "message-3"}

    monkeypatch.setattr(emails.GmailClient, "send_pdf", staticmethod(fake_send_pdf))
    student = _fake_student()
    upload = UploadFile(filename="Current_CV.pdf", file=io.BytesIO(b"%PDF-demo"))

    response = asyncio.run(
        emails.send_career_email(
            draft_id="draft-1",
            subject="Recommendation letter request",
            body="Hello Professor, would you write me a letter?",
            cv=upload,
            student=student,
            settings=Settings(),
        )
    )

    assert captured["attachment"] == b"%PDF-demo"
    assert response.attachment_name == "Current_CV.pdf"


def test_send_career_email_rejects_unknown_draft() -> None:
    student = _fake_student(pending_email_drafts={})

    with pytest.raises(HTTPException) as excinfo:
        asyncio.run(
            emails.send_career_email(
                draft_id="missing",
                subject="Subject line",
                body="A body long enough to pass validation checks.",
                cv=None,
                student=student,
                settings=Settings(),
            )
        )
    assert excinfo.value.status_code == 409


def test_send_career_email_requires_gmail_connected() -> None:
    student = _fake_student(gmail_access_token=None, gmail_email=None)

    with pytest.raises(HTTPException) as excinfo:
        asyncio.run(
            emails.send_career_email(
                draft_id="draft-1",
                subject="Recommendation letter request",
                body="Hello Professor, would you write me a letter?",
                cv=None,
                student=student,
                settings=Settings(),
            )
        )
    assert excinfo.value.status_code == 409


def test_preview_email_uses_transcript_and_writing_voice(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    def fake_generate(**kwargs):
        captured.update(kwargs)
        return EmailDraftContent(
            subject="Office-hours appointment request",
            body=(
                "Dear Professor,\n\nCould we arrange a short appointment "
                "about my graduation plan?\n\nBest regards,\nAda"
            ),
        )

    monkeypatch.setattr(emails, "generate_email_content", fake_generate)
    student = SimpleNamespace(
        academic=SimpleNamespace(
            current_season="Spring 2026",
            full_transcript=lambda: {
                "loaded_years": ["2022-2023", "2023-2024"],
                "cumulative_gpa": "1.4",
                "courses": [
                    {
                        "academic_year": "2023-2024",
                        "course": "Algorithms",
                        "grade": "A",
                        "hours": "5",
                    }
                ],
            },
        ),
        cms=SimpleNamespace(connected=False),
        resume_profile=None,
        linkedin_profile=None,
        github_profile=None,
        tone_profile={"Sample": "I prefer short and direct emails."},
        pending_email_drafts={},
        last_email_draft_id=None,
        chat_lock=threading.RLock(),
    )

    response = asyncio.run(
        emails.preview_career_email(
            payload=EmailDraftRequest(
                recipient_email="prof@giu-uni.de",
                sender_name="Ada Lovelace",
                purpose="Request an appointment about my graduation plan",
            ),
            student=student,
            settings=Settings(ANTHROPIC_API_KEY="test-key"),
        )
    )

    assert response.tone_applied is True
    assert "academic_transcript" in response.sources_used
    assert captured["candidate_name"] == "Ada Lovelace"
    assert "writing samples" in str(captured["tone_reference"])
    assert response.id in student.pending_email_drafts
