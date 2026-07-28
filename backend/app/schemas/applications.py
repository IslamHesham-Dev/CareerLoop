from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field, HttpUrl, model_validator


class ApplicationPreviewRequest(BaseModel):
    linkedin_post_url: HttpUrl | None = None
    post_text: str | None = Field(default=None, max_length=20_000)

    @model_validator(mode="after")
    def require_link_or_text(self) -> "ApplicationPreviewRequest":
        if self.linkedin_post_url is None and not (self.post_text or "").strip():
            raise ValueError("Provide a LinkedIn post link or paste the post text.")
        return self


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
    attachment_names: list[str] = Field(default_factory=list)
    sent_at: datetime
