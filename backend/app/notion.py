from __future__ import annotations

import base64
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

import requests


class NotionIntegrationError(RuntimeError):
    pass


@dataclass(frozen=True)
class NotionPage:
    page_id: str
    url: str


class NotionClient:
    base_url = "https://api.notion.com"

    def __init__(
        self,
        access_token: str,
        *,
        api_version: str,
        timeout: float = 30,
    ) -> None:
        self.access_token = access_token
        self.api_version = api_version
        self.timeout = timeout

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Notion-Version": self.api_version,
        }

    def create_markdown_page(
        self,
        *,
        title: str,
        markdown: str,
        sources: list[str],
        parent_page_id: str | None,
    ) -> NotionPage:
        page_markdown = self._document_markdown(
            title=title,
            markdown=markdown,
            sources=sources,
        )
        payload: dict[str, Any] = {
            "markdown": page_markdown,
            "icon": {"type": "emoji", "emoji": "🎓"},
        }
        if parent_page_id:
            payload["parent"] = {
                "type": "page_id",
                "page_id": parent_page_id,
            }
        else:
            payload["parent"] = {
                "type": "workspace",
                "workspace": True,
            }

        response = requests.post(
            f"{self.base_url}/v1/pages",
            headers=self.headers,
            json=payload,
            timeout=self.timeout,
        )
        data = self._json(response)
        if response.status_code < 200 or response.status_code >= 300:
            message = data.get("message")
            raise NotionIntegrationError(
                message
                if isinstance(message, str)
                else "Notion could not create the page."
            )
        page_id = data.get("id")
        page_url = data.get("url")
        if not isinstance(page_id, str) or not isinstance(page_url, str):
            raise NotionIntegrationError(
                "Notion returned an incomplete page response."
            )
        return NotionPage(page_id=page_id, url=page_url)

    @staticmethod
    def _document_markdown(
        *,
        title: str,
        markdown: str,
        sources: list[str],
    ) -> str:
        clean_title = " ".join(title.strip().split()) or "CareerLoop explanation"
        generated = datetime.now(UTC).strftime("%d %B %Y, %H:%M UTC")
        sections = [
            f"# {clean_title}",
            f"*Exported from CareerLoop on {generated}*",
            markdown.strip(),
        ]
        clean_sources = list(
            dict.fromkeys(source.strip() for source in sources if source.strip())
        )
        if clean_sources:
            sections.extend(
                [
                    "## Evidence used",
                    "\n".join(f"- {source}" for source in clean_sources),
                ]
            )
        sections.extend(
            [
                "---",
                "*Generated with CareerLoop. Verify important academic or "
                "career decisions with the original source.*",
            ]
        )
        return "\n\n".join(sections)

    @staticmethod
    def exchange_oauth_code(
        *,
        client_id: str,
        client_secret: str,
        redirect_uri: str,
        code: str,
        timeout: float = 30,
    ) -> dict[str, Any]:
        credentials = base64.b64encode(
            f"{client_id}:{client_secret}".encode("utf-8")
        ).decode("ascii")
        response = requests.post(
            f"{NotionClient.base_url}/v1/oauth/token",
            headers={
                "Authorization": f"Basic {credentials}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            json={
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": redirect_uri,
            },
            timeout=timeout,
        )
        data = NotionClient._json(response)
        if response.status_code < 200 or response.status_code >= 300:
            message = data.get("error_description") or data.get("message")
            raise NotionIntegrationError(
                message
                if isinstance(message, str)
                else "The Notion connection could not be completed."
            )
        return data

    @staticmethod
    def _json(response: requests.Response) -> dict[str, Any]:
        try:
            data = response.json()
        except ValueError:
            return {}
        return data if isinstance(data, dict) else {}
