"""app.tone: turn a student's own writing samples into an agent style reference.

    from app.tone import ONBOARDING_QUESTIONS, ToneProfile, ToneMiddleware

    profile = ToneProfile(answers=dict(zip(ONBOARDING_QUESTIONS, student_answers)))
    agent = create_agent(
        model=model, tools=[...], system_prompt=cv_generation_prompt,
        middleware=[ToneMiddleware(profile)],
    )

Storage-agnostic on purpose: this package only shapes and consumes a
`ToneProfile`, it does not decide where one is persisted. Whichever
onboarding-profile flow collects the answers just needs to build one (a
plain dict, trivial to serialize alongside the rest of that profile) and
hand it to any generation agent — CV, cover letter, email — that wants it.
"""

from .middleware import ToneMiddleware
from .models import ToneProfile
from .prompt import build_tone_reference
from .questions import ONBOARDING_QUESTIONS

__all__ = [
    "ONBOARDING_QUESTIONS",
    "ToneProfile",
    "ToneMiddleware",
    "build_tone_reference",
]
