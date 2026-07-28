"""Merge every available evidence source into one LLM-ready context dict.

Pure and network-free: every argument is data the caller already has on hand
(session fields, an `academic.full_transcript()` result, a list of CMS course
titles) — nothing here fetches anything itself. Tolerant of any source being
missing, mirroring the "not_connected" tolerance already used by the
get_*_profile agent tools in app/agent/factory.py: a student with only a
GitHub profile connected should still get a usable context, just a thinner
one.

Shared by every feature that needs "what do we know about this student":
`cv_generator` (CV content) and `email_generator` (career emails) both build
their prompts from this same merge, so evidence handling only lives in one
place. Deliberately lives at the `app/` level rather than inside either
generator package, since neither should depend on the other.
"""

from __future__ import annotations

from typing import Any

_STRONG_GRADES = {"A+", "A", "A-"}


def _strong_courses(courses: list[dict[str, Any]], *, top_n: int = 8) -> list[str]:
    """Course names with an A-range grade — the cheapest "this is CV-worthy"
    signal available from a transcript. De-duplicated, order-preserving, and
    capped so it doesn't blow up the prompt on a four-year transcript."""
    seen: set[str] = set()
    result: list[str] = []
    for row in courses:
        name = row.get("course")
        grade = str(row.get("grade", "")).strip()
        if not name or grade not in _STRONG_GRADES or name in seen:
            continue
        seen.add(name)
        result.append(name)
        if len(result) >= top_n:
            break
    return result


def build_career_context(
    *,
    resume_profile: dict[str, Any] | None = None,
    linkedin_profile: dict[str, Any] | None = None,
    github_profile: dict[str, Any] | None = None,
    transcript: dict[str, Any] | None = None,
    cms_course_titles: list[str] | None = None,
) -> dict[str, Any]:
    """One merged dict for a generator's LLM prompt to be built from.

    `sources_used` tells the caller (and can tell the model) which evidence
    actually went in, so output generated from GitHub alone can be honest
    about that rather than silently thin.
    """
    sources_used: list[str] = []
    context: dict[str, Any] = {}

    if resume_profile:
        sources_used.append("resume")
        context["resume"] = {
            "name": resume_profile.get("name"),
            "headline": resume_profile.get("headline"),
            "email": resume_profile.get("email"),
            "phone": resume_profile.get("phone"),
            "summary": resume_profile.get("summary"),
            "skills": resume_profile.get("skills") or [],
            "experience": resume_profile.get("experience") or [],
            "education": resume_profile.get("education") or [],
            "certifications": resume_profile.get("certifications") or [],
        }

    if linkedin_profile:
        sources_used.append("linkedin")
        context["linkedin"] = {
            "name": linkedin_profile.get("name"),
            "headline": linkedin_profile.get("headline"),
            "summary": linkedin_profile.get("summary"),
            "contact": linkedin_profile.get("contact") or [],
            "experience": linkedin_profile.get("experience") or [],
            "education": linkedin_profile.get("education") or [],
            "certifications": linkedin_profile.get("certifications") or [],
            "skills": linkedin_profile.get("skills") or [],
        }

    if github_profile:
        sources_used.append("github")
        context["github"] = {
            "login": github_profile.get("login"),
            "html_url": github_profile.get("html_url"),
            "languages": github_profile.get("languages") or {},
            # Already evidence-backed (skill/category/evidence_repos/weight)
            # via github_connector.extract_skills - pass through as-is.
            "skills": github_profile.get("skills") or [],
            "repositories": [
                {
                    "name": repo.get("name"),
                    "description": repo.get("description"),
                    "html_url": repo.get("html_url"),
                    "readme_excerpt": repo.get("readme_excerpt"),
                    "detected_skills": repo.get("detected_skills") or [],
                    "pushed_at": repo.get("pushed_at"),
                }
                for repo in (github_profile.get("repositories") or [])
            ],
        }

    if transcript:
        sources_used.append("academic_transcript")
        context["academic"] = {
            "cumulative_gpa": transcript.get("cumulative_gpa"),
            "loaded_years": transcript.get("loaded_years") or [],
            "course_count": len(transcript.get("courses") or []),
            "strong_courses": _strong_courses(transcript.get("courses") or []),
        }

    if cms_course_titles:
        sources_used.append("cms_courses")
        context["cms_course_titles"] = cms_course_titles[:40]

    context["sources_used"] = sources_used
    return context
