from __future__ import annotations

import asyncio
import io
import threading
from types import SimpleNamespace

import pytest
from fastapi import UploadFile
from fastapi.testclient import TestClient

from app.api.routes import career
from app.api.routes.career import (
    import_resume_profile,
    remove_resume_profile,
    resume_profile_status,
    sync_resume_profile,
)
from app.main import app
from app.schemas.career import ResumeProfile
from cv_connector import CVProfile, extract_cv_profile_from_text


def test_extract_cv_profile_from_text_extracts_common_fields() -> None:
    text = """
    Jane Doe
    Senior Software Engineer
    jane@example.com | +1 555 123 4567
    Summary: Experienced engineer with Python and FastAPI expertise.
    Skills: Python, FastAPI, Docker, AWS
    Education: BSc Computer Science, 2021
    Experience: Built APIs for fintech products.
    Certifications: AWS Certified Developer
    """

    profile = extract_cv_profile_from_text(text, file_name="cv.pdf")

    assert profile.name == "Jane Doe"
    assert profile.email == "jane@example.com"
    assert profile.phone == "+1 555 123 4567"
    assert "Python" in profile.skills
    assert "FastAPI" in profile.skills
    assert profile.education
    assert profile.experience


def test_extracts_every_experience_until_the_next_section() -> None:
    text = """
    Jane Doe
    Software Engineer
    jane@example.com
    Professional Experience
    Senior Engineer | Example One | 2024-Present
    Led the backend platform migration.
    Improved API reliability by 30 percent.
    Engineer | Example Two | 2022-2024
    Built customer-facing workflow services.
    Introduced automated integration tests.
    Junior Engineer | Example Three | 2020-2022
    Delivered internal Python tooling.
    Supported production incident reviews.
    Education
    BSc Computer Science
    Skills
    Python, FastAPI, Docker
    """

    profile = extract_cv_profile_from_text(text, file_name="full-history.pdf")

    assert any("Example One" in value for value in profile.experience)
    assert any("Example Two" in value for value in profile.experience)
    assert any("Example Three" in value for value in profile.experience)
    assert not any("BSc Computer Science" in value for value in profile.experience)


def _profile() -> ResumeProfile:
    return ResumeProfile(
        file_name="Jane_Doe_CV.pdf",
        imported_at="2026-07-27T12:00:00Z",
        page_count=1,
        name="Jane Doe",
        headline="Software Engineer",
        email="jane@example.com",
        phone="+1 555 123 4567",
        summary="Experienced engineer.",
        skills=["Python", "FastAPI"],
        experience=["Built APIs."],
        education=["BSc Computer Science"],
        certifications=[],
        raw_text=(
            "Jane Doe\nSoftware Engineer\nExperienced engineer with Python "
            "and FastAPI who built production APIs."
        ),
    )


def test_resume_profile_can_be_rehydrated_and_removed() -> None:
    student = SimpleNamespace(
        resume_profile=None,
        chat_lock=threading.RLock(),
        conversation=["stale context"],
        agent=object(),
    )
    profile = _profile()

    result = sync_resume_profile(profile, student=student)
    assert result.connected is True
    assert resume_profile_status(student=student).profile.name == "Jane Doe"
    assert student.conversation == []
    assert student.agent is None

    removed = remove_resume_profile(student=student)
    assert removed.message == "Resume profile removed."
    assert student.resume_profile is None


def test_resume_upload_extracts_and_loads_session(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    extracted = CVProfile(**_profile().model_dump())
    monkeypatch.setattr(
        career,
        "extract_cv_profile_from_bytes",
        lambda _content, *, file_name: extracted,
    )
    student = SimpleNamespace(
        resume_profile=None,
        chat_lock=threading.RLock(),
        conversation=["stale"],
        agent=object(),
    )
    upload = UploadFile(
        filename="Jane_Doe_CV.pdf",
        file=io.BytesIO(b"%PDF-demo"),
    )

    result = asyncio.run(import_resume_profile(file=upload, student=student))

    assert result.connected is True
    assert result.profile is not None
    assert result.profile.skills == ["Python", "FastAPI"]
    assert student.resume_profile["name"] == "Jane Doe"
    assert student.conversation == []


def test_resume_routes_are_exposed() -> None:
    with TestClient(app) as client:
        paths = client.get("/openapi.json").json()["paths"]

    assert "/v1/career/resume" in paths
    assert "/v1/career/resume/import" in paths
    assert "/v1/career/resume/sync" in paths
    assert "/v1/career/resume/remove" in paths
