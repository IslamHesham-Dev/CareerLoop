from __future__ import annotations

import asyncio
from types import SimpleNamespace

import requests

from app.api.routes import auth as auth_routes
from app.cms import UnavailableCmsService
from app.schemas.auth import LoginRequest


class _FakePortalSession:
    auth = object()
    closed = False

    def close(self) -> None:
        self.closed = True


class _FakePortal:
    def __init__(self, **kwargs) -> None:
        self.session = _FakePortalSession()

    def available_seasons(self, *, tries: int, delay: float):
        return [("67", "Winter 2025")]


class _RejectedCmsClient:
    closed = False

    def __init__(self, username: str, password: str) -> None:
        pass

    def list_courses(self, *, force: bool = False):
        raise requests.ConnectionError("CMS account is unavailable")

    def close(self) -> None:
        self.closed = True


class _FakeAcademic:
    current_season = "Winter 2025"
    advisory_year = "2024-2025"
    enrollment_year = 2021
    transcript_window_years = [
        "2021-2022",
        "2022-2023",
        "2023-2024",
        "2024-2025",
    ]

    def select_latest_actual_context(self) -> None:
        pass


class _FakeSessionStore:
    fallback: UnavailableCmsService | None = None

    def create(self, portal, cms, **kwargs):
        assert portal.session.closed is False
        assert isinstance(cms, UnavailableCmsService)
        self.fallback = cms
        student = SimpleNamespace(
            cms=cms,
            academic=_FakeAcademic(),
            expires_in_seconds=2700,
        )
        return "test-token", student


def test_portal_login_survives_when_cms_access_is_unavailable(
    monkeypatch,
) -> None:
    store = _FakeSessionStore()
    monkeypatch.setattr(auth_routes, "GucPortal", _FakePortal)
    monkeypatch.setattr(auth_routes, "GiuCmsClient", _RejectedCmsClient)
    monkeypatch.setattr(auth_routes, "session_store", store)

    response = asyncio.run(
        auth_routes.login(
            LoginRequest(
                username="student",
                password="secret",
                enrollment_year=2021,
            )
        )
    )

    assert response.access_token == "test-token"
    assert response.cms_connected is False
    assert "final-year or graduate" in response.cms_message
    assert store.fallback is not None
    assert store.fallback.list_courses(season="Winter 2025") == {
        "source": "GIU CMS",
        "status": "unavailable",
        "season": "Winter 2025",
        "courses": [],
        "message": response.cms_message,
    }
