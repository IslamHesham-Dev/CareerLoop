"""Fixed onboarding prompts used to elicit a student's natural writing voice.

Not "pick a tone" — self-reported formality is unreliable and no fun to fill
out during onboarding. Instead, four short, real writing samples in natural
contexts, so the samples themselves become `models.ToneProfile.answers` and
the reference `prompt.build_tone_reference` hands to the model. One question
per document type the rest of the roadmap needs a voice for: a self-intro
register, project storytelling, reflective tone, and an email sign-off for
the auto-send feature specifically.
"""

from __future__ import annotations

ONBOARDING_QUESTIONS: tuple[str, ...] = (
    "Introduce yourself in 2-3 sentences, like you're messaging a recruiter "
    "you want to work for.",
    "Describe a project you're proud of, in your own words, like you're "
    "telling a friend about it.",
    "Tell us about a mistake or setback and what you learned from it.",
    "How would you close an email asking for a follow-up on a job "
    "application?",
)
