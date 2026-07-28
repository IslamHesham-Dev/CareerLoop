"""The one LLM call in the CV pipeline: structured content, never raw LaTeX.

Turns `aggregate.build_career_context`'s merged evidence into a validated
`CVContent` via Anthropic tool-calling structured output
(`with_structured_output`), so the result is guaranteed schema-valid before
it ever reaches `latex_template.render_latex`. Nothing here touches LaTeX.
"""

from __future__ import annotations

import json
from typing import Any

from github_connector import SKILL_EXTRACTION_GUIDANCE
from app.llm import build_chat_model_for

from .models import CVContent

_BASE_INSTRUCTIONS = """
You are writing a one-page CV for a student, from verified evidence only.

Ground rules:
- Every claim must trace back to something in the evidence below (resume,
  LinkedIn import, GitHub evidence, transcript, CMS course titles). Never
  invent an employer, project, certification, or skill that isn't present
  in at least one source.
- When sources conflict (e.g. resume and LinkedIn phrase the same role
  differently), prefer the more detailed/specific account; don't silently
  merge them into a claim neither source actually makes.
- Group skills by category (e.g. "language", "backend framework",
  "database", "devops") rather than one flat list.
- Keep the summary to 2-3 sentences.
- Bullets are outcome-oriented and concrete ("built X that did Y"), not
  generic ("worked on various projects").
- Use the imported resume as the most detailed evidence for work history,
  education, certifications, phone, and email. Preserve every relevant
  experience rather than keeping only the newest one.
- Set contact.github_url to the connected GitHub profile html_url and
  contact.linkedin_url to the imported LinkedIn profile_url whenever those
  values exist. Never substitute guessed URLs.
- Select at most three GitHub projects that best demonstrate the target
  role. Use repository name, URL, README excerpt, description, detected
  skills, topics, and languages to write accurate titles, technology stacks,
  and bullets. Do not turn a language percentage or repository name into an
  unsupported accomplishment.
- Make the headline and summary specific to the target role while remaining
  truthful to the candidate's career and academic evidence.
- Keep the complete rendered document to one page: prefer 2-4 bullets per
  relevant role/project and omit weak or duplicate claims.
- Every section is optional: omit any section with no supporting evidence
  rather than padding it.
""".strip()


def generate_cv_content(
    *,
    career_context: dict[str, Any],
    api_key: str,
    model: str,
    provider: str = "anthropic",
    target_position: str = "",
    target_company: str = "",
    custom_input: str = "",
    tone_reference: str = "",
) -> CVContent:
    """One structured-output call producing a validated `CVContent`.

    `tone_reference` is expected to already be the output of
    `app.tone.build_tone_reference` (or "" if the student has no tone
    profile yet) - this function just appends it, it doesn't know anything
    about `ToneProfile` itself.
    """
    sections = [_BASE_INSTRUCTIONS]

    if career_context.get("github"):
        sections.append(SKILL_EXTRACTION_GUIDANCE)

    if target_position or target_company:
        target_line = "Tailor this CV for the position"
        if target_position:
            target_line += f' "{target_position}"'
        if target_company:
            target_line += f" at {target_company}"
        target_line += (
            ". Reorder and select for relevance to this target first, "
            "completeness second - deprioritize off-target evidence, don't "
            "delete it if it's still a genuine, evidenced skill."
        )
        sections.append(target_line)

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
        temperature=0.3,
        api_key=api_key,
    )
    result = llm.with_structured_output(CVContent).invoke(prompt)
    if isinstance(result, CVContent):
        return result
    return CVContent.model_validate(result)
