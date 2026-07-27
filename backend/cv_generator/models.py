"""The LLM's only output: structured CV content, never freehand LaTeX.

Freehand LaTeX from a model risks unescaped `&`/`%`/`_`/`#`, unbalanced
braces, and a broken compile — exactly the failure mode you don't want live
at a demo. Instead, the model fills this schema (via structured output) and
`latex_template.render_latex` deterministically turns it into a `.tex`
document, escaping every field on the way. That split — LLM judgment for
content, plain code for rendering — is the same reasoning behind
github_connector's parse/network split and app.tone's prompt/middleware
split.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class ContactInfo(BaseModel):
    email: str | None = None
    phone: str | None = None
    location: str | None = None
    linkedin_url: str | None = None
    github_url: str | None = None
    website_url: str | None = None


class SkillGroup(BaseModel):
    """One category's worth of skills, e.g. category='backend framework'."""

    category: str
    skills: list[str] = Field(default_factory=list, max_length=25)


class ExperienceEntry(BaseModel):
    title: str
    organization: str
    dates: str  # free text, e.g. "Jun 2025 - Aug 2025"; no date math needed for a demo
    bullets: list[str] = Field(default_factory=list, max_length=8)


class ProjectEntry(BaseModel):
    name: str
    dates: str | None = None
    technologies: list[str] = Field(default_factory=list, max_length=12)
    bullets: list[str] = Field(default_factory=list, max_length=6)
    url: str | None = None


class EducationEntry(BaseModel):
    institution: str
    degree: str
    dates: str
    gpa_or_honors: str | None = None
    highlights: list[str] = Field(default_factory=list, max_length=6)


class CVContent(BaseModel):
    """Everything `latex_template.render_latex` needs to fill the template."""

    full_name: str
    headline: str | None = None
    summary: str = Field(max_length=800)
    contact: ContactInfo = Field(default_factory=ContactInfo)
    skills: list[SkillGroup] = Field(default_factory=list, max_length=10)
    experience: list[ExperienceEntry] = Field(default_factory=list, max_length=8)
    projects: list[ProjectEntry] = Field(default_factory=list, max_length=8)
    education: list[EducationEntry] = Field(default_factory=list, max_length=5)
    certifications: list[str] = Field(default_factory=list, max_length=15)
