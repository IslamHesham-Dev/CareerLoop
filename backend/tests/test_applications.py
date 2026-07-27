from __future__ import annotations

import asyncio
import base64
import io
import time
from email import policy
from email.parser import BytesParser
from types import SimpleNamespace
from urllib.parse import parse_qs, urlparse

import pytest
from fastapi import UploadFile

from app.api.routes import applications
from app.application_service import (
    ApplicationIntakeError,
    generate_application_draft,
    linkedin_post_text,
)
from app.config import Settings
from app.gmail import GMAIL_SEND_SCOPE, GmailClient


def test_linkedin_intake_prefers_user_supplied_post_text() -> None:
    text = (
        "We are hiring a Junior Flutter Engineer. Email your CV to "
        "jobs@example.com and mention the mobile team."
    )
    result, source, warnings = linkedin_post_text(
        "https://www.linkedin.com/posts/example",
        supplied_text=text,
    )
    assert result == text
    assert source == "user_pasted"
    assert warnings == []


def test_linkedin_intake_rejects_non_linkedin_urls() -> None:
    with pytest.raises(ApplicationIntakeError):
        linkedin_post_text(
            "https://example.com/fake-post",
            supplied_text="A" * 80,
        )


def test_fallback_draft_extracts_role_and_contact_without_inventing() -> None:
    draft = generate_application_draft(
        post_text=(
            "We are hiring for Flutter Engineer at Example Labs. "
            "Please email your CV to hiring@example.com."
        ),
        candidate_name="Islam Hesham",
        linkedin_profile=None,
        github_profile=None,
        settings=Settings(ANTHROPIC_API_KEY=""),
    )
    assert "Flutter Engineer" in draft.role
    assert draft.detected_contact_email == "hiring@example.com"
    assert "Islam Hesham" in draft.body
    assert "attached" in draft.body.casefold()


def test_gmail_oauth_requests_send_only_mail_permission() -> None:
    url = GmailClient.authorization_url(
        client_id="client",
        redirect_uri="https://api.example.com/callback",
        state="state",
    )
    scope = parse_qs(urlparse(url).query)["scope"][0].split()
    assert GMAIL_SEND_SCOPE in scope
    assert "https://www.googleapis.com/auth/gmail.readonly" not in scope
    assert "https://mail.google.com/" not in scope


def test_gmail_send_builds_pdf_mime_message(monkeypatch: pytest.MonkeyPatch) -> None:
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
    result = GmailClient.send_pdf(
        access_token="access",
        sender="candidate@gmail.com",
        recipient="prototype@gmail.com",
        subject="Application — Engineer",
        body="Hello, my current CV is attached.",
        attachment=b"%PDF-demo",
        attachment_name="Islam_Hesham_CV.pdf",
    )
    raw = captured["json"]["raw"]  # type: ignore[index]
    message = BytesParser(policy=policy.default).parsebytes(
        base64.urlsafe_b64decode(raw)
    )
    assert result["id"] == "message-1"
    assert message["From"] == "candidate@gmail.com"
    assert message["To"] == "prototype@gmail.com"
    attachments = list(message.iter_attachments())
    assert len(attachments) == 1
    assert attachments[0].get_filename() == "Islam_Hesham_CV.pdf"
    assert attachments[0].get_payload(decode=True) == b"%PDF-demo"


def test_send_endpoint_enforces_server_recipient(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, object] = {}

    def fake_send_pdf(**kwargs):
        captured.update(kwargs)
        return {"id": "message-2", "threadId": "thread-2"}

    monkeypatch.setattr(
        applications.GmailClient,
        "send_pdf",
        staticmethod(fake_send_pdf),
    )
    student = SimpleNamespace(
        pending_application_drafts={
            "a" * 32: {
                "recipient": "attacker@example.com",
                "created_at": time.time(),
            }
        },
        gmail_access_token="access",
        gmail_refresh_token="refresh",
        gmail_token_expires_at=time.time() + 3600,
        gmail_email="candidate@gmail.com",
    )
    upload = UploadFile(
        filename="Current_CV.pdf",
        file=io.BytesIO(b"%PDF-demo"),
    )
    response = asyncio.run(
        applications.send_application(
            application_id="a" * 32,
            subject="Application — Engineer",
            body="Hello, please find my current CV attached.",
            cv=upload,
            student=student,
            settings=Settings(),
        )
    )
    assert captured["recipient"] == "islammheshamm7@gmail.com"
    assert response.recipient == "islammheshamm7@gmail.com"
    assert ("a" * 32) not in student.pending_application_drafts
