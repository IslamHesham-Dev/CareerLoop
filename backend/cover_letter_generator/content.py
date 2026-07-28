"""Grounded, structured cover-letter generation."""

from __future__ import annotations

import json
from typing import Any

from langchain_anthropic import ChatAnthropic

from .models import CoverLetterContent


def generate_cover_letter_content(
    *,
    career_context: dict[str, Any],
    job_posting: dict[str, Any],
    api_key: str,
    model: str,
    custom_input: str = "",
    tone_reference: str = "",
) -> CoverLetterContent:
    prompt = f"""
You write a concise, credible, one-page cover letter using verified evidence.

Rules:
- Every candidate claim must be supported by the imported resume, LinkedIn
  PDF, connected GitHub repositories, or academic transcript in EVIDENCE.
- Treat the imported resume as the primary evidence for contact details,
  experience, education, and certifications.
- Tailor every paragraph to the supplied job and company. Use the most
  relevant verified experience and GitHub projects, including concrete
  technologies or outcomes only when the evidence supports them.
- Mention academic evidence only when it strengthens this role.
- Never invent a hiring-manager name, requirement, project metric, employer,
  address, LinkedIn URL, or GitHub URL.
- Set contact.github_url from github.html_url and contact.linkedin_url from
  linkedin.profile_url when present.
- Use 3 or 4 short paragraphs: motivation and fit; strongest relevant
  evidence; a second distinct evidence point; concise close and call to action.
- The subject must identify the exact role and company.
- Do not add template commentary or markdown.

JOB:
{json.dumps(job_posting, indent=2, default=str)}

EVIDENCE:
{json.dumps(career_context, indent=2, default=str)}

STUDENT REFINEMENT:
{custom_input or "(none)"}

TONE REFERENCE:
{tone_reference or "(no saved tone profile)"}
""".strip()

    llm = ChatAnthropic(model=model, temperature=0.35, api_key=api_key)
    result = llm.with_structured_output(CoverLetterContent).invoke(prompt)
    if isinstance(result, CoverLetterContent):
        return result
    return CoverLetterContent.model_validate(result)

