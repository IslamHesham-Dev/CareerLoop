from __future__ import annotations

import base64
from typing import Any

import pytest
import requests
from fastapi.testclient import TestClient

from app.main import app
from app.notion import NotionClient, NotionIntegrationError
from app.config import Settings


class _Response:
    def __init__(self, status_code: int, payload: dict[str, Any]) -> None:
        self.status_code = status_code
        self._payload = payload

    def json(self) -> dict[str, Any]:
        return self._payload


def test_notion_export_creates_a_grounded_markdown_page(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, Any] = {}

    def fake_post(url: str, **kwargs: Any) -> _Response:
        captured.update(url=url, **kwargs)
        return _Response(
            200,
            {
                "id": "page-123",
                "url": "https://www.notion.so/page-123",
            },
        )

    monkeypatch.setattr(requests, "post", fake_post)
    page = NotionClient(
        "secret-token",
        api_version="2026-03-11",
    ).create_markdown_page(
        title="ICS501 explanation",
        markdown="## Result\n\nThe project grade is **55 / 95**.",
        sources=["GIU Portal", "GIU Portal", "CMS Week 4"],
        parent_page_id="parent-123",
    )

    assert page.page_id == "page-123"
    assert captured["url"] == "https://api.notion.com/v1/pages"
    assert captured["headers"]["Authorization"] == "Bearer secret-token"
    assert captured["headers"]["Notion-Version"] == "2026-03-11"
    assert captured["json"]["parent"]["page_id"] == "parent-123"
    markdown = captured["json"]["markdown"]
    assert markdown.startswith("# ICS501 explanation")
    assert "The project grade is **55 / 95**." in markdown
    assert markdown.count("- GIU Portal") == 1
    assert "- CMS Week 4" in markdown


def test_notion_export_surfaces_the_api_error(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        requests,
        "post",
        lambda *args, **kwargs: _Response(
            403,
            {"message": "The integration has no access to this page."},
        ),
    )

    with pytest.raises(NotionIntegrationError, match="no access"):
        NotionClient(
            "secret-token",
            api_version="2026-03-11",
        ).create_markdown_page(
            title="Explanation",
            markdown="Content",
            sources=[],
            parent_page_id="private-page",
        )


def test_notion_oauth_exchange_uses_basic_auth(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, Any] = {}

    def fake_post(url: str, **kwargs: Any) -> _Response:
        captured.update(url=url, **kwargs)
        return _Response(
            200,
            {
                "access_token": "oauth-token",
                "workspace_name": "Student workspace",
            },
        )

    monkeypatch.setattr(requests, "post", fake_post)
    result = NotionClient.exchange_oauth_code(
        client_id="client-id",
        client_secret="client-secret",
        redirect_uri="https://careerloop.test/callback",
        code="temporary-code",
    )

    encoded = base64.b64encode(b"client-id:client-secret").decode("ascii")
    assert result["access_token"] == "oauth-token"
    assert captured["url"] == "https://api.notion.com/v1/oauth/token"
    assert captured["headers"]["Authorization"] == f"Basic {encoded}"
    assert captured["json"]["code"] == "temporary-code"


def test_notion_routes_are_exposed() -> None:
    with TestClient(app) as client:
        paths = client.get("/openapi.json").json()["paths"]

    assert "/v1/integrations/notion/status" in paths
    assert "/v1/integrations/notion/connect" in paths
    assert "/v1/integrations/notion/callback" in paths
    assert "/v1/integrations/notion/export" in paths


def test_notion_settings_accept_render_friendly_aliases(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("NOTION_INTEGRATION_TOKEN", "secret-token")
    monkeypatch.setenv("NOTION_PAGE_ID", "parent-page")

    settings = Settings(_env_file=None)

    assert settings.notion_api_key.get_secret_value() == "secret-token"
    assert settings.notion_parent_page_id == "parent-page"
