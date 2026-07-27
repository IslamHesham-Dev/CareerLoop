from __future__ import annotations

from typing import Literal

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


class OpportunityPreferences(BaseModel):
    role_type: Literal["internship", "newgrad"] = "newgrad"
    timeframe: Literal["lastday", "lastweek", "lastmonth"] = "lastweek"
    target_market: Literal["europe", "local", "remote", "global"] = "europe"
    locations: list[str] = Field(default_factory=list, max_length=12)
    keywords: list[str] = Field(default_factory=list, max_length=16)
    work_modes: list[
        Literal["remote", "hybrid", "onsite"]
    ] = Field(default_factory=list, max_length=3)


class OpportunitySearchRequest(OpportunityPreferences):
    limit: int = Field(default=24, ge=1, le=40)


class OpportunityEvidence(BaseModel):
    academic_transcript: bool
    linkedin_pdf: bool
    github: bool
    resume: bool


class JobMatch(BaseModel):
    id: str
    company: str
    title: str
    location: str
    url: str
    source: str
    role_family: str
    match_score: int = Field(ge=0, le=100)
    match_reasons: list[str]
    keyword_matches: list[str]
    profile_skill_matches: list[str]
    inferred_skill_gaps: list[str]
    recommended_course_ids: list[str]


class CareerCourse(BaseModel):
    id: str
    title: str
    provider: str
    platform: str
    url: str
    level: str
    duration: str
    skills: list[str]
    roles: list[str]
    addresses_skills: list[str]
    catalog_source: str


class OpportunitySearchResponse(BaseModel):
    source: str
    source_detail: str
    searched_at: str
    preferences: OpportunityPreferences
    evidence: OpportunityEvidence
    jobs: list[JobMatch]
    recommended_courses: list[CareerCourse]
    message: str | None = None
    limitations: list[str]


class OpportunityStatusResponse(BaseModel):
    source: str
    connected: bool
    adzuna_connected: bool
    course_count: int
    preferences: OpportunityPreferences | None = None
