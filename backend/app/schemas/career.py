from __future__ import annotations

from pydantic import BaseModel, Field


class LinkedInProfile(BaseModel):
    file_name: str = Field(min_length=1, max_length=240)
    imported_at: str
    page_count: int = Field(ge=1, le=25)
    name: str | None = Field(default=None, max_length=200)
    headline: str | None = Field(default=None, max_length=500)
    summary: str | None = Field(default=None, max_length=12_000)
    contact: list[str] = Field(default_factory=list, max_length=40)
    experience: list[str] = Field(default_factory=list, max_length=200)
    education: list[str] = Field(default_factory=list, max_length=100)
    certifications: list[str] = Field(default_factory=list, max_length=100)
    skills: list[str] = Field(default_factory=list, max_length=100)
    raw_text: str = Field(min_length=20, max_length=60_000)


class LinkedInProfileStatus(BaseModel):
    connected: bool
    profile: LinkedInProfile | None = None


class LinkedInProfileMessage(BaseModel):
    message: str
