from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class EmailDraftRequest(BaseModel):
    recipient_email: str = Field(min_length=5, max_length=320)
    sender_name: str = Field(min_length=2, max_length=100)
    purpose: str = Field(min_length=5, max_length=1500)
    custom_input: str = Field(default="", max_length=2000)


class EmailDraftResponse(BaseModel):
    id: str
    recipient_email: str
    purpose: str
    subject: str
    body: str
    sources_used: list[str] = Field(default_factory=list)
    tone_applied: bool = False
    created_at: str


class EmailSendResponse(BaseModel):
    message_id: str
    thread_id: str | None = None
    sender: str
    recipient: str
    subject: str
    attachment_name: str | None = None
    sent_at: datetime
