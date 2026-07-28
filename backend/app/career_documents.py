"""Job-specific resume and cover-letter generation for the mobile studio."""

from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timezone
from typing import Any, Literal

from app.career_context import build_career_context
from app.config import Settings
from app.schemas.career import JobDocumentTarget
from app.sessions.models import StudentSession
from app.tone import ToneProfile, build_tone_reference
from cover_letter_generator import CoverLetterGenerator
from cv_generator import CVGenerator

DocumentKind = Literal["resume", "cover_letter"]
_MAX_DOCUMENTS_PER_SESSION = 8


class CareerDocumentError(RuntimeError):
    pass


def generate_document(
    *,
    student: StudentSession,
    settings: Settings,
    kind: DocumentKind,
    job: JobDocumentTarget,
    instructions: str = "",
    existing: dict[str, Any] | None = None,
) -> dict[str, Any]:
    api_key = settings.anthropic_api_key.get_secret_value()
    if not api_key:
        raise CareerDocumentError(
            "ANTHROPIC_API_KEY is not configured on the backend."
        )
    context = _career_context(student)
    if not context.get("sources_used"):
        raise CareerDocumentError(
            "No profile or academic evidence is available for this document."
        )

    tone_reference = (
        build_tone_reference(ToneProfile(answers=student.tone_profile))
        if student.tone_profile
        else ""
    )
    revision_instruction = instructions.strip()
    if existing:
        revision_instruction = (
            "Revise the current document using the student's instruction. "
            "Preserve accurate content that was not requested to change.\n"
            f"Current validated draft:\n"
            f"{json.dumps(existing.get('content', {}), indent=2)}\n"
            f"Student instruction: {revision_instruction}"
        )

    job_payload = job.model_dump()
    if kind == "resume":
        result = CVGenerator(
            anthropic_api_key=api_key,
            model=settings.anthropic_model,
        ).generate(
            career_context=context,
            target_position=job.title,
            target_company=job.company,
            custom_input=revision_instruction,
            tone_reference=tone_reference,
        )
        content = result.content.model_dump()
        pdf_bytes = result.pdf_bytes
        latex_source = result.latex_source
        preview = result.content.summary
        candidate_name = result.content.full_name
    else:
        result = CoverLetterGenerator(
            anthropic_api_key=api_key,
            model=settings.anthropic_model,
        ).generate(
            career_context=context,
            job_posting=job_payload,
            custom_input=revision_instruction,
            tone_reference=tone_reference,
        )
        content = result.content.model_dump()
        pdf_bytes = result.pdf_bytes
        latex_source = result.latex_source
        preview = result.content.paragraphs[0]
        candidate_name = result.content.candidate_name

    if pdf_bytes is None:
        raise CareerDocumentError(
            "The document content was generated, but this deployment has no "
            "working LaTeX compiler. Redeploy the backend with Tectonic."
        )

    now = datetime.now(timezone.utc).isoformat()
    document_id = str(existing["id"]) if existing else uuid.uuid4().hex
    version = int(existing.get("version", 0)) + 1 if existing else 1
    slug_name = _filename_part(candidate_name or "Candidate")
    slug_company = _filename_part(job.company)
    slug_role = _filename_part(job.title)
    suffix = "Resume" if kind == "resume" else "Cover_Letter"
    filename = (
        f"{slug_name}_{slug_company}_{slug_role}_{suffix}_v{version}.pdf"
    )
    record: dict[str, Any] = {
        "id": document_id,
        "kind": kind,
        "version": version,
        "filename": filename,
        "title": (
            "Tailored resume" if kind == "resume" else "Tailored cover letter"
        ),
        "company": job.company,
        "job_title": job.title,
        "job": job_payload,
        "preview": preview,
        "sources_used": list(context.get("sources_used", [])),
        "content": content,
        "latex_source": latex_source,
        "pdf_bytes": pdf_bytes,
        "created_at": existing.get("created_at", now) if existing else now,
        "updated_at": now,
    }
    with student.chat_lock:
        student.career_documents[document_id] = record
        _trim_documents(student.career_documents)
    return record


def public_document(record: dict[str, Any]) -> dict[str, Any]:
    return {
        key: record[key]
        for key in (
            "id",
            "kind",
            "version",
            "filename",
            "title",
            "company",
            "job_title",
            "preview",
            "sources_used",
            "created_at",
            "updated_at",
        )
    } | {"pdf_path": f"/v1/career/documents/{record['id']}/pdf"}


def _career_context(student: StudentSession) -> dict[str, Any]:
    try:
        transcript = student.academic.full_transcript()
    except Exception:
        transcript = None

    cms_course_titles: list[str] | None = None
    if student.cms.connected:
        try:
            payload = student.cms.list_courses(
                season=student.academic.current_season
            )
            cms_course_titles = [
                course.get("title") or course.get("code") or ""
                for course in payload.get("courses", [])
            ]
            cms_course_titles = [item for item in cms_course_titles if item]
        except Exception:
            cms_course_titles = None

    return build_career_context(
        resume_profile=student.resume_profile,
        linkedin_profile=student.linkedin_profile,
        github_profile=student.github_profile,
        transcript=transcript,
        cms_course_titles=cms_course_titles,
    )


def _filename_part(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_")
    return cleaned[:50] or "Document"


def _trim_documents(documents: dict[str, dict[str, Any]]) -> None:
    if len(documents) <= _MAX_DOCUMENTS_PER_SESSION:
        return
    oldest = sorted(
        documents.values(),
        key=lambda item: str(item.get("updated_at", "")),
    )
    for record in oldest[: len(documents) - _MAX_DOCUMENTS_PER_SESSION]:
        documents.pop(str(record["id"]), None)
