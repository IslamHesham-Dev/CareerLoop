"""The one LLM call in the email pipeline: a grounded, tone-matched draft.

Generalizes app.application_service.generate_application_draft (scoped
narrowly to "reply to a scraped LinkedIn job post") to an arbitrary,
student-stated purpose and an arbitrary recipient - "ask a professor for a
recommendation," "follow up on an internship application," "introduce
myself to a recruiter." Same evidence-grounding discipline: every claim must
trace back to app.career_context.build_career_context's merged evidence,
never invented.
"""

from __future__ import annotations

import json
from typing import Any

from app.llm import build_chat_model_for

from .models import EmailDraftContent

_BASE_INSTRUCTIONS = """
You are drafting a short, professional email on a student's behalf, for
them to review and edit before it is ever sent - nothing you write here is
sent automatically.

Ground rules:
- Every factual claim (a project, a skill, a grade, an employer) must trace
  back to the evidence below. Never invent an experience, qualification, or
  detail that isn't present in at least one source.
- Match the stated purpose precisely: a recommendation-letter request reads
  differently from a job-application follow-up or a cold introduction.
  Don't pad a short, purpose-appropriate email with generic filler.
- Keep it concise: 80-150 words for the body is typical unless the purpose
  clearly calls for more.
- Do not fabricate a greeting name if none is known; use a neutral
  greeting ("Hello," or "Dear Hiring Team,") instead.
- End with the student's name, not a placeholder.
- Never write a subject line that overpromises or misrepresents the
  student's background.
""".strip()


def generate_email_content(
    *,
    purpose: str,
    recipient_email: str,
    candidate_name: str,
    career_context: dict[str, Any],
    api_key: str,
    model: str,
    provider: str = "anthropic",
    custom_input: str = "",
    tone_reference: str = "",
) -> EmailDraftContent:
    """One structured-output call producing a validated `EmailDraftContent`.

    `tone_reference` is expected to already be the output of
    `app.tone.build_tone_reference` (or "" if the student has no tone
    profile yet) - this function just appends it, same as `cv_generator`.
    """
    sections = [_BASE_INSTRUCTIONS]

    sections.append(
        f'Purpose of this email, in the student\'s own words: "{purpose}"\n'
        f"Recipient email address: {recipient_email}\n"
        f"Student's name (sign the email with this): {candidate_name}"
    )

    if custom_input:
        sections.append(f"Additional instructions from the student: {custom_input}")

    if tone_reference:
        sections.append(tone_reference)

    sections.append(
        "Evidence (JSON; every fact you use must come from here):\n"
        + json.dumps(career_context, indent=2, default=str)
    )

    prompt = "\n\n".join(sections)

    llm = build_chat_model_for(
        provider=provider,
        model=model,
        temperature=0.4,
        api_key=api_key,
    )
    result = llm.with_structured_output(EmailDraftContent).invoke(prompt)
    if isinstance(result, EmailDraftContent):
        return result
    return EmailDraftContent.model_validate(result)
