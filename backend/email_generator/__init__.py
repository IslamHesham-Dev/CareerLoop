"""email_generator: draft a grounded, tone-matched career email.

    from app.career_context import build_career_context
    from email_generator import generate_email_content

    context = build_career_context(...)
    draft = generate_email_content(
        purpose="ask my professor to write a recommendation letter",
        recipient_email="prof@giu-uni.de",
        candidate_name="Ada Lovelace",
        career_context=context,
        api_key=api_key,
        model=settings.anthropic_model,
        tone_reference=tone_reference,
    )
    draft.subject
    draft.body

Drafting only - this package never sends anything itself. Sending is a
separate, explicit, human-confirmed action; see app/api/routes/emails.py.
"""

from .content import generate_email_content
from .models import EmailDraftContent

__all__ = ["generate_email_content", "EmailDraftContent"]
