from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field, HttpUrl


class ApplicationPreviewRequest(BaseModel):
    linkedin_post_url: HttpUrl
    post_text: str | None = Field(default=None, max_length=20_000)


class ApplicationDraftResponse(BaseModel):
    id: str
    linkedin_post_url: str
    content_source: str
    post_excerpt: str
    role: str
    company: str | None = None
    contact_name: str | None = None
    detected_contact_email: str | None = None
    recipient: str
    prototype_recipient_locked: bool = True
    subject: str
    body: str
    sender_email: str | None = None
    gmail_connected: bool
    warnings: list[str] = Field(default_factory=list)


class ApplicationSendResponse(BaseModel):
    message_id: str
    thread_id: str | None = None
    sender: str
    recipient: str
    subject: str
    attachment_name: str
    sent_at: datetime
