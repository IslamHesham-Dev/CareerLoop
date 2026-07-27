"""Turn a student's own writing samples into a style-reference prompt block.

Deliberately mechanical: no NLP classification, no formality score, no
"detected tone: casual" label. The samples ARE the reference — the model is
asked to imitate the voice they show, not match a label someone assigned to
it. Kept separate from `middleware.py` so the plain string this produces can
be tested, read, and tweaked without touching any LangChain plumbing.
"""

from __future__ import annotations

from .models import ToneProfile


def build_tone_reference(profile: ToneProfile) -> str:
    """A system-prompt block: the student's own words, plus imitation rules.

    Returns an empty string when the profile has no (non-blank) answers, so a
    middleware built from an empty profile is a safe no-op instead of
    injecting a confusing, sample-free instruction block.
    """
    samples = "\n\n".join(
        f'Q: {question}\nA: "{answer.strip()}"'
        for question, answer in profile.answers.items()
        if answer.strip()
    )
    if not samples:
        return ""

    return (
        "Below are unedited writing samples from the student, in their own "
        "words. When generating any text on their behalf (CV bullet points, "
        "a cover letter, an email), match the voice evidenced here — "
        "sentence length and rhythm, level of formality, typical word "
        "choices, use of humor or directness — as closely as the samples "
        "support. Treat these as a style reference only: never copy their "
        "sentences into generated output verbatim, and never reuse facts "
        "mentioned in them as content for a different document without the "
        "student's own input for that document.\n\n"
        f"{samples}"
    )
