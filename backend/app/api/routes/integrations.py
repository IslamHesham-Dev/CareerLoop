from __future__ import annotations

import html
import secrets
import time
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import HTMLResponse

from app.config import Settings, get_settings
from app.dependencies import get_student_session
from app.notion import NotionClient, NotionIntegrationError
from app.schemas.integrations import (
    NotionConnectResponse,
    NotionExportRequest,
    NotionExportResponse,
    NotionStatusResponse,
)
from app.sessions.models import StudentSession
from app.state import session_store

router = APIRouter(prefix="/integrations", tags=["integrations"])


def _internal_token(settings: Settings) -> str:
    return settings.notion_api_key.get_secret_value().strip()


def _oauth_configured(settings: Settings) -> bool:
    return all(
        (
            settings.notion_oauth_client_id.strip(),
            settings.notion_oauth_client_secret.get_secret_value().strip(),
            settings.notion_oauth_redirect_uri.strip(),
        )
    )


@router.get("/notion/status", response_model=NotionStatusResponse)
def notion_status(
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> NotionStatusResponse:
    internal_ready = bool(
        _internal_token(settings) and settings.notion_parent_page_id.strip()
    )
    oauth_ready = _oauth_configured(settings)
    connected = internal_ready or bool(student.notion_access_token)
    mode = "internal" if internal_ready else "oauth" if oauth_ready else "disabled"
    return NotionStatusResponse(
        available=internal_ready or oauth_ready,
        connected=connected,
        mode=mode,
        workspace_name=student.notion_workspace_name,
    )


@router.post("/notion/connect", response_model=NotionConnectResponse)
def connect_notion(
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> NotionConnectResponse:
    if _internal_token(settings) and settings.notion_parent_page_id.strip():
        return NotionConnectResponse(connected=True)
    if student.notion_access_token:
        return NotionConnectResponse(connected=True)
    if not _oauth_configured(settings):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Notion export has not been configured on the backend.",
        )

    oauth_state = secrets.token_urlsafe(32)
    student.notion_oauth_state = oauth_state
    student.notion_oauth_expires_at = time.time() + 10 * 60
    query = urlencode(
        {
            "client_id": settings.notion_oauth_client_id,
            "response_type": "code",
            "owner": "user",
            "redirect_uri": settings.notion_oauth_redirect_uri,
            "state": oauth_state,
        }
    )
    return NotionConnectResponse(
        connected=False,
        authorization_url=f"https://api.notion.com/v1/oauth/authorize?{query}",
    )


@router.get("/notion/callback", response_class=HTMLResponse)
async def notion_callback(
    code: str | None = Query(default=None),
    state: str | None = Query(default=None),
    error: str | None = Query(default=None),
    settings: Settings = Depends(get_settings),
) -> HTMLResponse:
    if error:
        return _callback_page(
            "Connection cancelled",
            "Notion access was not granted. You can close this page.",
            success=False,
        )
    if not code or not state:
        return _callback_page(
            "Invalid connection",
            "The authorization response was incomplete.",
            success=False,
            status_code=status.HTTP_400_BAD_REQUEST,
        )
    student = session_store.find_by_notion_oauth_state(state)
    if student is None:
        return _callback_page(
            "Connection expired",
            "Return to CareerLoop and start the Notion connection again.",
            success=False,
            status_code=status.HTTP_400_BAD_REQUEST,
        )
    try:
        result = await run_in_threadpool(
            NotionClient.exchange_oauth_code,
            client_id=settings.notion_oauth_client_id,
            client_secret=settings.notion_oauth_client_secret.get_secret_value(),
            redirect_uri=settings.notion_oauth_redirect_uri,
            code=code,
        )
        access_token = result.get("access_token")
        if not isinstance(access_token, str) or not access_token:
            raise NotionIntegrationError(
                "Notion did not return an access token."
            )
        student.notion_access_token = access_token
        workspace_name = result.get("workspace_name")
        student.notion_workspace_name = (
            workspace_name if isinstance(workspace_name, str) else None
        )
        student.notion_oauth_state = None
        student.notion_oauth_expires_at = None
    except NotionIntegrationError as exc:
        return _callback_page(
            "Connection failed",
            str(exc),
            success=False,
            status_code=status.HTTP_502_BAD_GATEWAY,
        )
    return _callback_page(
        "Notion connected",
        "Return to CareerLoop. Your next export will take one tap.",
        success=True,
    )


@router.post("/notion/export", response_model=NotionExportResponse)
async def export_to_notion(
    payload: NotionExportRequest,
    student: StudentSession = Depends(get_student_session),
    settings: Settings = Depends(get_settings),
) -> NotionExportResponse:
    internal_token = _internal_token(settings)
    parent_page_id = settings.notion_parent_page_id.strip() or None
    access_token = internal_token or student.notion_access_token
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Connect Notion before exporting this response.",
        )
    if internal_token and parent_page_id is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="NOTION_PARENT_PAGE_ID is missing on the backend.",
        )
    try:
        page = await run_in_threadpool(
            NotionClient(
                access_token,
                api_version=settings.notion_api_version,
            ).create_markdown_page,
            title=payload.title,
            markdown=payload.markdown,
            sources=payload.sources,
            parent_page_id=parent_page_id if internal_token else None,
        )
    except NotionIntegrationError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from None
    return NotionExportResponse(
        page_id=page.page_id,
        page_url=page.url,
        title=payload.title,
    )


def _callback_page(
    title: str,
    message: str,
    *,
    success: bool,
    status_code: int = status.HTTP_200_OK,
) -> HTMLResponse:
    color = "#1F9D86" if success else "#D95D6F"
    body = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)}</title>
</head>
<body style="margin:0;background:#F5F5F1;color:#172033;
  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif">
  <main style="max-width:460px;margin:12vh auto;padding:32px">
    <div style="width:48px;height:48px;border-radius:14px;background:{color};
      display:grid;place-items:center;color:white;font-size:24px">✓</div>
    <h1 style="font-size:28px;margin:24px 0 8px">{html.escape(title)}</h1>
    <p style="color:#667085;line-height:1.55">{html.escape(message)}</p>
  </main>
</body>
</html>"""
    return HTMLResponse(content=body, status_code=status_code)
