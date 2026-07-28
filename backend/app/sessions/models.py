from __future__ import annotations

import threading
import time
from dataclasses import dataclass, field
from typing import Any

from guc_portal import GucPortal

from app.academic import AcademicService
from app.cms import CmsService, UnavailableCmsService


@dataclass
class StudentSession:
    session_id: str
    institution: str
    portal: GucPortal
    academic: AcademicService
    cms: CmsService | UnavailableCmsService
    created_at: float
    expires_at: float
    conversation: list[Any] = field(default_factory=list)
    agent: Any = None
    pending_practice_set: dict[str, Any] | None = None
    notion_access_token: str | None = None
    notion_workspace_name: str | None = None
    notion_oauth_state: str | None = None
    notion_oauth_expires_at: float | None = None
    linkedin_profile: dict[str, Any] | None = None
    resume_profile: dict[str, Any] | None = None
    tone_profile: dict[str, str] | None = None
    github_access_token: str | None = None
    github_profile: dict[str, Any] | None = None
    github_device_code: str | None = None
    github_device_expires_at: float | None = None
    github_poll_interval: int = 5
    github_last_poll_at: float | None = None
    gmail_access_token: str | None = None
    gmail_refresh_token: str | None = None
    gmail_token_expires_at: float | None = None
    gmail_email: str | None = None
    gmail_oauth_state: str | None = None
    gmail_oauth_expires_at: float | None = None
    pending_application_drafts: dict[str, dict[str, Any]] = field(
        default_factory=dict
    )
    pending_email_drafts: dict[str, dict[str, Any]] = field(default_factory=dict)
    last_email_draft_id: str | None = None
    career_preferences: dict[str, Any] | None = None
    career_documents: dict[str, dict[str, Any]] = field(default_factory=dict)
    chat_lock: threading.RLock = field(default_factory=threading.RLock)

    @property
    def expires_in_seconds(self) -> int:
        return max(0, int(self.expires_at - time.time()))

    @property
    def university_label(self) -> str:
        return self.institution.upper()

    def close(self) -> None:
        self.conversation.clear()
        self.agent = None
        self.pending_practice_set = None
        self.notion_access_token = None
        self.notion_workspace_name = None
        self.notion_oauth_state = None
        self.notion_oauth_expires_at = None
        self.linkedin_profile = None
        self.resume_profile = None
        self.tone_profile = None
        self.github_access_token = None
        self.github_profile = None
        self.github_device_code = None
        self.github_device_expires_at = None
        self.github_poll_interval = 5
        self.github_last_poll_at = None
        self.gmail_access_token = None
        self.gmail_refresh_token = None
        self.gmail_token_expires_at = None
        self.gmail_email = None
        self.gmail_oauth_state = None
        self.gmail_oauth_expires_at = None
        self.pending_application_drafts.clear()
        self.pending_email_drafts.clear()
        self.last_email_draft_id = None
        self.career_preferences = None
        self.career_documents.clear()
        self.academic.clear_cache()
        self.cms.close()
        self.portal.session.auth = None
        self.portal.session.close()
