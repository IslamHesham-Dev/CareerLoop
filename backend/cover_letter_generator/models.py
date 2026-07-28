"""Validated content used to fill the fixed CareerLoop cover-letter template."""

from __future__ import annotations

from pydantic import BaseModel, Field

from cv_generator.models import ContactInfo


class CoverLetterContent(BaseModel):
    candidate_name: str
    professional_title: str | None = None
    contact: ContactInfo = Field(default_factory=ContactInfo)
    recipient: str = "Hiring Team"
    subject: str
    greeting: str = "Dear Hiring Manager,"
    paragraphs: list[str] = Field(min_length=3, max_length=4)
    signoff: str = "Yours faithfully,"

