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
    chat_lock: threading.RLock = field(default_factory=threading.RLock)

    @property
    def expires_in_seconds(self) -> int:
        return max(0, int(self.expires_at - time.time()))

    def close(self) -> None:
        self.conversation.clear()
        self.agent = None
        self.pending_practice_set = None
        self.notion_access_token = None
        self.notion_workspace_name = None
        self.notion_oauth_state = None
        self.notion_oauth_expires_at = None
        self.linkedin_profile = None
        self.academic.clear_cache()
        self.cms.close()
        self.portal.session.auth = None
        self.portal.session.close()
