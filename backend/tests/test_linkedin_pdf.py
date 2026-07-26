from __future__ import annotations

import threading
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app import linkedin_pdf
from app.api.routes.career import (
    linkedin_profile_status,
    remove_linkedin_profile,
    sync_linkedin_profile,
)
from app.linkedin_pdf import LinkedInPdfError, extract_linkedin_profile
from app.main import app
from app.schemas.career import LinkedInProfile


class _Page:
    def __init__(self, text: str) -> None:
        self.text = text

    def extract_text(self, **_kwargs) -> str:
        return self.text


class _Reader:
    is_encrypted = False

    def __init__(self, _stream, *, text: str) -> None:
        self.pages = [_Page(text)]


def test_linkedin_pdf_extracts_professional_evidence(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    text = """Ada Lovelace
Software Engineer
Berlin, Germany
Summary
I build reliable analytical systems.
Experience
Software Engineer
Example GmbH
2024 - Present
Education
GIU
BSc Computer Science
Certifications
Cloud Foundations
Top Skills
Python
Distributed Systems
Contact
ada@example.com
https://linkedin.com/in/ada
"""
    monkeypatch.setattr(
        linkedin_pdf,
        "PdfReader",
        lambda stream: _Reader(stream, text=text),
    )

    profile = extract_linkedin_profile(
        b"%PDF-fake",
        file_name="Ada LinkedIn Profile.pdf",
    )

    assert profile.name == "Ada Lovelace"
    assert profile.headline == "Software Engineer"
    assert profile.summary == "I build reliable analytical systems."
    assert "Example GmbH" in profile.experience
    assert "GIU" in profile.education
    assert profile.certifications == ["Cloud Foundations"]
    assert profile.skills == ["Python", "Distributed Systems"]
    assert "ada@example.com" in profile.contact
    assert profile.page_count == 1


def test_linkedin_pdf_rejects_a_scan_without_text(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        linkedin_pdf,
        "PdfReader",
        lambda stream: _Reader(stream, text=""),
    )

    with pytest.raises(LinkedInPdfError, match="selectable text"):
        extract_linkedin_profile(b"%PDF-fake", file_name="scan.pdf")


def test_certification_is_never_used_as_profile_identity(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    text = """Contact
ada@example.com
Certifications
Certified Cloud Professional
Ada Lovelace
Software Engineer
Berlin, Germany
Summary
I build reliable analytical systems.
"""
    monkeypatch.setattr(
        linkedin_pdf,
        "PdfReader",
        lambda stream: _Reader(stream, text=text),
    )

    profile = extract_linkedin_profile(
        b"%PDF-fake",
        file_name="LinkedIn Profile.pdf",
    )

    assert profile.name != "Certified Cloud Professional"
    assert profile.name is None
    assert profile.headline is None


def test_linkedin_profile_can_be_rehydrated_and_removed() -> None:
    profile = LinkedInProfile(
        file_name="LinkedIn.pdf",
        imported_at="2026-07-26T12:00:00Z",
        page_count=2,
        name="Ada Lovelace",
        headline="Software Engineer",
        summary="Builds systems.",
        contact=[],
        experience=["Example GmbH"],
        education=["GIU"],
        certifications=[],
        skills=["Python"],
        raw_text="Ada Lovelace\nSoftware Engineer\nBuilds systems.",
    )
    student = SimpleNamespace(
        linkedin_profile=None,
        chat_lock=threading.RLock(),
        conversation=["old career context"],
        agent=object(),
    )

    synced = sync_linkedin_profile(profile, student=student)
    assert synced.connected is True
    assert linkedin_profile_status(student=student).profile.name == "Ada Lovelace"
    assert student.conversation == []
    assert student.agent is None

    removed = remove_linkedin_profile(student=student)
    assert removed.message == "LinkedIn PDF profile removed."
    assert student.linkedin_profile is None


def test_linkedin_profile_routes_are_exposed() -> None:
    with TestClient(app) as client:
        paths = client.get("/openapi.json").json()["paths"]

    assert "/v1/career/linkedin-profile" in paths
    assert "/v1/career/linkedin-profile/import" in paths
    assert "/v1/career/linkedin-profile/sync" in paths
    assert "/v1/career/linkedin-profile/remove" in paths
