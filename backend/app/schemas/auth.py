from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, SecretStr


class LoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=160)
    password: SecretStr
    enrollment_year: int = Field(ge=2000, le=2100)
    institution: Literal["giu", "guc"] = "giu"


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    current_season: str
    advisory_year: str
    enrollment_year: int
    institution: Literal["giu", "guc"]
    transcript_years: list[str]
    cms_connected: bool
    cms_message: str | None = None
    username: str


class SessionResponse(BaseModel):
    authenticated: bool
    expires_in_seconds: int
    current_season: str
    advisory_year: str
    enrollment_year: int
    institution: Literal["giu", "guc"]
    transcript_years: list[str]
    cms_connected: bool
    cms_message: str | None = None
    username: str


class MessageResponse(BaseModel):
    message: str
