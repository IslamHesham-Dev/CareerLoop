from __future__ import annotations

from pydantic import BaseModel, Field


class NotionStatusResponse(BaseModel):
    available: bool
    connected: bool
    mode: str
    workspace_name: str | None = None
    configuration_message: str | None = None


class NotionConnectResponse(BaseModel):
    connected: bool
    authorization_url: str | None = None


class NotionExportRequest(BaseModel):
    title: str = Field(default="CareerLoop explanation", max_length=160)
    markdown: str = Field(min_length=1, max_length=100_000)
    sources: list[str] = Field(default_factory=list, max_length=30)


class NotionExportResponse(BaseModel):
    page_id: str
    page_url: str
    title: str
