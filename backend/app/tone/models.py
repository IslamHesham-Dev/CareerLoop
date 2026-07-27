"""Plain data holder for a student's tone-elicitation answers.

Deliberately just text: no formality score, no derived label like "casual" or
"formal". The raw answers ARE the reference `prompt.build_tone_reference`
hands to the model — scoring or classifying them would throw away exactly
the texture that makes generated text sound like the student.

Storage is intentionally not this module's job. Whichever onboarding-profile
flow collects the answers (in-memory session, a JSON file, a database row —
whatever it ends up being) only needs to build one of these; `answers` is a
plain `dict[str, str]`, trivially serializable however that flow already
stores the rest of the profile.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class ToneProfile:
    """One student's raw answers to `questions.ONBOARDING_QUESTIONS`."""

    answers: dict[str, str] = field(default_factory=dict)  # question -> raw answer
