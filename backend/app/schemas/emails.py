from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class EmailSendResponse(BaseModel):
    message_id: str
    thread_id: str | None = None
    sender: str
    recipient: str
    subject: str
    attachment_name: str | None = None
    sent_at: datetime
