from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from datetime import UTC, datetime
from io import BytesIO
from pathlib import Path
from typing import Any

from pypdf import PdfReader


class CVExtractionError(ValueError):
    pass


@dataclass
class CVProfile:
    file_name: str
    imported_at: str
    page_count: int
    name: str | None = None
    headline: str | None = None
    email: str | None = None
    phone: str | None = None
    summary: str | None = None
    skills: list[str] = field(default_factory=list)
    experience: list[str] = field(default_factory=list)
    education: list[str] = field(default_factory=list)
    certifications: list[str] = field(default_factory=list)
    raw_text: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "file_name": self.file_name,
            "imported_at": self.imported_at,
            "page_count": self.page_count,
            "name": self.name,
            "headline": self.headline,
            "email": self.email,
            "phone": self.phone,
            "summary": self.summary,
            "skills": self.skills,
            "experience": self.experience,
            "education": self.education,
            "certifications": self.certifications,
            "raw_text": self.raw_text,
        }


def extract_cv_profile_from_bytes(content: bytes, *, file_name: str) -> CVProfile:
    if not content:
        raise CVExtractionError("The selected PDF is empty.")
    try:
        reader = PdfReader(BytesIO(content))
    except Exception as exc:
        raise CVExtractionError("The selected file is not a readable PDF.") from exc
    if reader.is_encrypted:
        try:
            unlocked = reader.decrypt("")
        except Exception:
            unlocked = 0
        if not unlocked:
            raise CVExtractionError("Password-protected PDFs are not supported.")
    if not reader.pages:
        raise CVExtractionError("The PDF contains no pages.")
    if len(reader.pages) > 25:
        raise CVExtractionError("Choose a resume with 25 pages or fewer.")

    pages: list[str] = []
    for page in reader.pages:
        try:
            pages.append(page.extract_text() or "")
        except Exception:
            pages.append("")
    text = _normalize_text("\n".join(pages))
    if len(text) < 40:
        raise CVExtractionError("No selectable text was found in the PDF.")
    return extract_cv_profile_from_text(text, file_name=file_name, page_count=len(reader.pages))


def extract_cv_profile_from_text(
    text: str,
    *,
    file_name: str,
    page_count: int = 1,
) -> CVProfile:
    normalized = _normalize_text(text)[:60_000]
    if len(normalized) < 40:
        raise CVExtractionError("No selectable text was found in the PDF.")

    name = _extract_name(normalized)
    headline = _extract_headline(normalized)
    email = _extract_email(normalized)
    phone = _extract_phone(normalized)
    summary = _extract_section(normalized, ["summary", "profile", "about"])
    skills = _extract_skills(normalized)
    experience = _extract_list_section(
        normalized,
        [
            "experience",
            "work experience",
            "professional experience",
            "employment history",
            "work history",
            "career history",
        ],
    )
    education = _extract_list_section(normalized, ["education", "academic background"])
    certifications = _extract_list_section(normalized, ["certifications", "licenses and certifications"])

    return CVProfile(
        file_name=(Path(file_name).name or "cv.pdf")[:240],
        imported_at=datetime.now(UTC).isoformat(),
        page_count=page_count,
        name=name,
        headline=headline,
        email=email,
        phone=phone,
        summary=summary,
        skills=skills,
        experience=experience,
        education=education,
        certifications=certifications,
        raw_text=normalized,
    )


def _normalize_text(text: str) -> str:
    text = text.replace("\x00", "").replace("\r\n", "\n").replace("\r", "\n")
    lines = []
    for value in text.splitlines():
        line = re.sub(r"[ \t]+", " ", value).strip()
        if line:
            lines.append(line)
    return "\n".join(lines)


def _extract_name(text: str) -> str | None:
    first_line = text.splitlines()[0].strip() if text.splitlines() else ""
    if first_line and len(first_line.split()) <= 6:
        return first_line[:200]
    return None


def _extract_headline(text: str) -> str | None:
    lines = text.splitlines()
    for line in lines[1:6]:
        if len(line.split()) <= 12 and not re.search(r"@|\+\d|http", line):
            return line[:500]
    return None


def _extract_email(text: str) -> str | None:
    match = re.search(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", text, re.IGNORECASE)
    return match.group(0) if match else None


def _extract_phone(text: str) -> str | None:
    match = re.search(r"\+?\d[\d ()-]{7,}\d", text)
    return match.group(0).strip()[:100] if match else None


def _extract_section(text: str, labels: list[str]) -> str | None:
    lines = text.splitlines()
    lowered = [line.casefold() for line in lines]
    for index, line in enumerate(lowered):
        for label in labels:
            if line.startswith(label + ":") or line == label:
                inline = lines[index].split(":", 1)
                section_lines = (
                    [inline[1].strip()]
                    if len(inline) == 2 and inline[1].strip()
                    else []
                )
                for follow in lines[index + 1 : index + 8]:
                    if _is_section_heading(follow):
                        break
                    section_lines.append(follow)
                return " ".join(section_lines).strip()[:12_000] or None
    return None


def _extract_skills(text: str) -> list[str]:
    lines = text.splitlines()
    for index, line in enumerate(lines):
        lowered = line.casefold()
        if lowered.startswith("skills:") or lowered.startswith("technical skills:"):
            value = line.split(":", 1)[1].strip()
            return [item.strip() for item in re.split(r"[,;|]", value) if item.strip()]
        if lowered in {"skills", "technical skills"}:
            values: list[str] = []
            for follow in lines[index + 1 : index + 7]:
                if _is_section_heading(follow):
                    break
                values.extend(
                    item.strip()
                    for item in re.split(r"[,;|•]", follow)
                    if item.strip()
                )
            return values
    return []


def _extract_list_section(text: str, labels: list[str]) -> list[str]:
    lines = text.splitlines()
    lowered = [line.casefold() for line in lines]
    for index, line in enumerate(lowered):
        for label in labels:
            if line.startswith(label + ":") or line == label:
                inline = lines[index].split(":", 1)
                values = (
                    [inline[1].strip()]
                    if len(inline) == 2 and inline[1].strip()
                    else []
                )
                for follow in lines[index + 1 :]:
                    if _is_section_heading(follow):
                        break
                    if follow.strip() and len(values) < 200:
                        values.append(follow.strip())
                return values
    return []


_SECTION_HEADINGS = {
    "about",
    "academic background",
    "achievements",
    "awards",
    "certifications",
    "education",
    "employment history",
    "experience",
    "career history",
    "interests",
    "languages",
    "leadership",
    "leadership experience",
    "licenses and certifications",
    "publications",
    "profile",
    "professional experience",
    "projects",
    "selected projects",
    "skills",
    "summary",
    "technical skills",
    "volunteer experience",
    "volunteering",
    "work experience",
    "work history",
}


def _is_section_heading(value: str) -> bool:
    normalized = value.strip().casefold()
    label = normalized.split(":", 1)[0].strip().rstrip(":")
    return label in _SECTION_HEADINGS
