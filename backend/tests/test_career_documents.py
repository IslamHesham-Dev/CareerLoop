from app.career_context import build_career_context
from app.career_documents import document_pdf, document_versions, public_document
from cover_letter_generator.latex_template import render_cover_letter_latex
from cover_letter_generator.models import CoverLetterContent
from cv_generator.models import ContactInfo


def test_career_context_exposes_verified_profile_links_and_repo_metadata() -> None:
    context = build_career_context(
        linkedin_profile={
            "name": "Ada",
            "raw_text": "Profile https://www.linkedin.com/in/ada-lovelace",
        },
        github_profile={
            "login": "ada",
            "html_url": "https://github.com/ada",
            "repositories": [
                {
                    "name": "engine",
                    "html_url": "https://github.com/ada/engine",
                    "primary_language": "Python",
                    "languages": {"Python": 2000},
                    "topics": ["agents"],
                    "stars": 3,
                }
            ],
        },
    )

    assert context["linkedin"]["profile_url"].endswith("/ada-lovelace")
    assert context["github"]["html_url"] == "https://github.com/ada"
    assert context["github"]["repositories"][0]["primary_language"] == "Python"
    assert context["github"]["repositories"][0]["topics"] == ["agents"]


def test_cover_letter_template_escapes_evidence_and_uses_verified_links() -> None:
    tex = render_cover_letter_latex(
        CoverLetterContent(
            candidate_name="Ada & Co",
            professional_title="AI Engineer",
            contact=ContactInfo(
                email="ada_test@example.com",
                linkedin_url="https://linkedin.com/in/ada",
                github_url="https://github.com/ada",
            ),
            recipient="R&D Hiring Team",
            subject="Application for AI & Platform Engineer",
            paragraphs=[
                "I build safe R&D systems.",
                "I improved throughput by 50%.",
                "I would welcome an interview.",
            ],
        )
    )

    assert r"Ada \& Co" in tex
    assert r"R\&D Hiring Team" in tex
    assert r"50\%" in tex
    assert "https://github.com/ada" in tex
    assert "https://linkedin.com/in/ada" in tex


def test_public_document_never_exposes_pdf_or_latex_bytes() -> None:
    record = {
        "id": "doc-1",
        "kind": "resume",
        "version": 1,
        "filename": "Ada_Resume.pdf",
        "title": "Tailored resume",
        "company": "Analytical Engines",
        "job_title": "Engineer",
        "preview": "Evidence-backed profile.",
        "sources_used": ["resume", "github"],
        "created_at": "2026-07-28T10:00:00+00:00",
        "updated_at": "2026-07-28T10:00:00+00:00",
        "pdf_bytes": b"secret-pdf",
        "latex_source": r"\documentclass{article}",
    }

    payload = public_document(record)

    assert payload["pdf_path"] == "/v1/career/documents/doc-1/pdf?version=1"
    assert "pdf_bytes" not in payload
    assert "latex_source" not in payload


def test_document_history_keeps_each_pdf_version_downloadable() -> None:
    record = {
        "id": "doc-1",
        "kind": "resume",
        "version": 2,
        "filename": "Ada_Resume_v2.pdf",
        "title": "Tailored resume",
        "company": "Analytical Engines",
        "job_title": "Engineer",
        "job": {
            "id": "job-1",
            "company": "Analytical Engines",
            "title": "Engineer",
        },
        "preview": "Version two.",
        "sources_used": ["resume", "github"],
        "created_at": "2026-07-28T10:00:00+00:00",
        "updated_at": "2026-07-28T11:00:00+00:00",
        "pdf_bytes": b"version-two",
        "latex_source": "v2",
        "versions": [
            {
                "kind": "resume",
                "version": 1,
                "filename": "Ada_Resume_v1.pdf",
                "title": "Tailored resume",
                "company": "Analytical Engines",
                "job_title": "Engineer",
                "job": {
                    "id": "job-1",
                    "company": "Analytical Engines",
                    "title": "Engineer",
                },
                "preview": "Version one.",
                "sources_used": ["resume"],
                "created_at": "2026-07-28T10:00:00+00:00",
                "updated_at": "2026-07-28T10:00:00+00:00",
                "pdf_bytes": b"version-one",
                "latex_source": "v1",
            },
        ],
    }

    versions = document_versions(record)

    assert versions[0]["version"] == 1
    assert versions[0]["pdf_path"].endswith("?version=1")
    assert document_pdf(record, 1) == (b"version-one", "Ada_Resume_v1.pdf")
    assert document_pdf(record, 2) == (b"version-two", "Ada_Resume_v2.pdf")
