from __future__ import annotations

import re
from datetime import UTC, datetime
from io import BytesIO
from pathlib import Path

from pypdf import PdfReader

from app.schemas.career import LinkedInProfile

MAX_LINKEDIN_PDF_BYTES = 10 * 1024 * 1024
MAX_LINKEDIN_PDF_PAGES = 25

_SECTION_NAMES = {
    "contact": "contact",
    "top skills": "skills",
    "skills": "skills",
    "certifications": "certifications",
    "licenses & certifications": "certifications",
    "licenses and certifications": "certifications",
    "summary": "summary",
    "about": "summary",
    "experience": "experience",
    "education": "education",
}

_NON_NAME_TERMS = {
    "academy",
    "badge",
    "certification",
    "certified",
    "certificate",
    "course",
    "credential",
    "diploma",
    "foundations",
    "license",
    "professional",
    "specialist",
}


class LinkedInPdfError(ValueError):
    pass


def extract_linkedin_profile(
    content: bytes,
    *,
    file_name: str,
) -> LinkedInProfile:
    if not content:
        raise LinkedInPdfError("The selected PDF is empty.")
    if len(content) > MAX_LINKEDIN_PDF_BYTES:
        raise LinkedInPdfError("The LinkedIn PDF must be 10 MB or smaller.")
    try:
        reader = PdfReader(BytesIO(content))
    except Exception as exc:
        raise LinkedInPdfError(
            "The selected file is not a readable PDF."
        ) from exc
    if reader.is_encrypted:
        try:
            unlocked = reader.decrypt("")
        except Exception:
            unlocked = 0
        if not unlocked:
            raise LinkedInPdfError(
                "Password-protected PDFs are not supported."
            )
    page_count = len(reader.pages)
    if page_count == 0:
        raise LinkedInPdfError("The PDF contains no pages.")
    if page_count > MAX_LINKEDIN_PDF_PAGES:
        raise LinkedInPdfError(
            f"The LinkedIn PDF must have at most {MAX_LINKEDIN_PDF_PAGES} pages."
        )

    pages: list[str] = []
    font_spans: list[tuple[str, float]] = []
    for page in reader.pages:
        try:
            page_spans: list[tuple[str, float]] = []

            def capture_text(
                text: str,
                _cm,
                _tm,
                _font_dictionary,
                font_size: float,
            ) -> None:
                for value in text.splitlines():
                    line = re.sub(r"[ \t]+", " ", value).strip()
                    if line:
                        page_spans.append((line, float(font_size or 0)))

            try:
                page_text = page.extract_text(visitor_text=capture_text) or ""
            except TypeError:
                # Test doubles and older pypdf versions may not expose the
                # visitor API. The conservative text-only fallback below will
                # still work when identity precedes the first section.
                page_text = page.extract_text() or ""
            pages.append(page_text)
            font_spans.extend(page_spans)
        except Exception:
            pages.append("")
    raw_text = _normalize_text("\n".join(pages))
    if len(raw_text) < 20:
        raise LinkedInPdfError(
            "No selectable text was found. Export the PDF directly from "
            "LinkedIn instead of uploading a screenshot."
        )
    raw_text = raw_text[:60_000]
    sections, unsectioned = _split_sections(raw_text)
    name, headline = _identity(unsectioned, raw_text, font_spans)
    return LinkedInProfile(
        file_name=_safe_file_name(file_name),
        imported_at=datetime.now(UTC).isoformat(),
        page_count=page_count,
        name=name,
        headline=headline,
        summary=_joined(sections.get("summary", []), limit=12_000),
        contact=sections.get("contact", [])[:40],
        experience=sections.get("experience", [])[:200],
        education=sections.get("education", [])[:100],
        certifications=sections.get("certifications", [])[:100],
        skills=sections.get("skills", [])[:100],
        raw_text=raw_text,
    )


def _normalize_text(text: str) -> str:
    text = text.replace("\x00", "").replace("\r\n", "\n").replace("\r", "\n")
    lines = []
    for value in text.splitlines():
        line = re.sub(r"[ \t]+", " ", value).strip()
        if not line or re.fullmatch(r"Page \d+ of \d+", line, re.IGNORECASE):
            continue
        lines.append(line)
    return "\n".join(lines)


def _split_sections(
    text: str,
) -> tuple[dict[str, list[str]], list[str]]:
    sections: dict[str, list[str]] = {}
    unsectioned: list[str] = []
    current: str | None = None
    for line in text.splitlines():
        section = _SECTION_NAMES.get(line.casefold().rstrip(":"))
        if section:
            current = section
            sections.setdefault(section, [])
            continue
        if current is None:
            unsectioned.append(line)
        else:
            sections[current].append(line)
    return sections, unsectioned


def _identity(
    unsectioned: list[str],
    raw_text: str,
    font_spans: list[tuple[str, float]],
) -> tuple[str | None, str | None]:
    # LinkedIn's two-column PDF can extract the sidebar first. Font size is the
    # reliable signal: the profile name is visually prominent, while a
    # certification title is ordinary body text.
    name = _font_identity(font_spans)
    if name is not None:
        return name, _headline_after(name, raw_text)

    # Conservative fallback for linear PDFs. Never scan backwards from
    # "Summary": that region can belong to Certifications in a two-column
    # extraction and caused certification names to be presented as identity.
    candidates = [
        line
        for line in unsectioned[:12]
        if not _looks_like_contact(line) and len(line) <= 200
    ]
    name_index = next(
        (
            index
            for index, line in enumerate(candidates)
            if _looks_like_person_name(line)
        ),
        None,
    )
    if name_index is None:
        return None, None
    name = candidates[name_index]
    headline = candidates[name_index + 1] if name_index + 1 < len(candidates) else None
    return name, headline


def _font_identity(font_spans: list[tuple[str, float]]) -> str | None:
    candidates = [
        (line, size)
        for line, size in font_spans
        if _looks_like_person_name(line)
    ]
    if not candidates:
        return None
    sizes = sorted(size for _, size in font_spans if size > 0)
    if not sizes:
        return None
    median = sizes[len(sizes) // 2]
    name, size = max(candidates, key=lambda item: item[1])
    # Require genuine visual prominence. If the PDF does not preserve that
    # signal, showing no name is safer than inventing an identity.
    if size < max(11.0, median * 1.18):
        return None
    return name


def _headline_after(name: str, raw_text: str) -> str | None:
    lines = raw_text.splitlines()
    try:
        name_index = lines.index(name)
    except ValueError:
        return None
    for line in lines[name_index + 1 : name_index + 4]:
        if (
            line.casefold().rstrip(":") in _SECTION_NAMES
            or _looks_like_contact(line)
            or _looks_like_location(line)
            or len(line) > 200
        ):
            continue
        return line
    return None


def _looks_like_person_name(value: str) -> bool:
    words = value.split()
    lowered_words = {
        re.sub(r"[^\w-]", "", word, flags=re.UNICODE).casefold()
        for word in words
    }
    return (
        2 <= len(words) <= 6
        and all(re.fullmatch(r"[^\W\d_][^\d_]*", word, re.UNICODE) for word in words)
        and not any(character in value for character in "@|:/")
        and lowered_words.isdisjoint(_NON_NAME_TERMS)
    )


def _looks_like_contact(value: str) -> bool:
    lowered = value.casefold()
    return (
        "linkedin.com/" in lowered
        or "http://" in lowered
        or "https://" in lowered
        or "@" in value
        or bool(re.search(r"\+?\d[\d ()-]{7,}", value))
    )


def _looks_like_location(value: str) -> bool:
    return "," in value and 1 < len(value.split()) <= 8


def _joined(lines: list[str], *, limit: int) -> str | None:
    value = "\n".join(lines).strip()
    return value[:limit] if value else None


def _safe_file_name(value: str) -> str:
    name = Path(value).name.strip() or "LinkedIn_Profile.pdf"
    return name[:240]
