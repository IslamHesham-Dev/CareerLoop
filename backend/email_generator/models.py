"""The LLM's only output for a career email: subject + body, nothing else.

Kept small on purpose. Unlike a CV there's no rendering/compile stage, so
there's nothing to over-structure — the draft is plain text, and formatting
(line breaks, sign-off) is the model's job within `content.py`'s guardrails.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class EmailDraftContent(BaseModel):
    subject: str = Field(min_length=3, max_length=200)
    body: str = Field(min_length=20, max_length=5000)
