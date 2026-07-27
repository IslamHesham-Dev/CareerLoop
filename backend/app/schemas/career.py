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


class ResumeProfile(BaseModel):
    file_name: str = Field(min_length=1, max_length=240)
    imported_at: str
    page_count: int = Field(ge=1, le=25)
    name: str | None = Field(default=None, max_length=200)
    headline: str | None = Field(default=None, max_length=500)
    email: str | None = Field(default=None, max_length=320)
    phone: str | None = Field(default=None, max_length=100)
    summary: str | None = Field(default=None, max_length=12_000)
    skills: list[str] = Field(default_factory=list, max_length=150)
    experience: list[str] = Field(default_factory=list, max_length=250)
    education: list[str] = Field(default_factory=list, max_length=100)
    certifications: list[str] = Field(default_factory=list, max_length=100)
    raw_text: str = Field(min_length=20, max_length=60_000)


class ResumeProfileStatus(BaseModel):
    connected: bool
    profile: ResumeProfile | None = None


class ResumeProfileMessage(BaseModel):
    message: str


class GithubSkillEvidence(BaseModel):
    skill: str
    category: str
    evidence_repos: list[str] = Field(default_factory=list, max_length=40)
    weight: float = Field(ge=0)


class GithubRepositoryEvidence(BaseModel):
    name: str
    full_name: str
    description: str | None = None
    html_url: str
    primary_language: str | None = None
    languages: dict[str, int] = Field(default_factory=dict)
    topics: list[str] = Field(default_factory=list, max_length=40)
    stars: int = Field(default=0, ge=0)
    forks: int = Field(default=0, ge=0)
    pushed_at: str | None = None
    readme_excerpt: str | None = Field(default=None, max_length=1600)
    detected_skills: list[str] = Field(default_factory=list, max_length=60)


class GithubProfileEvidence(BaseModel):
    login: str
    name: str | None = None
    bio: str | None = None
    company: str | None = None
    location: str | None = None
    avatar_url: str | None = None
    html_url: str
    public_repos: int = Field(ge=0)
    followers: int = Field(ge=0)
    repository_count: int = Field(ge=0)
    analyzed_repository_count: int = Field(ge=0)
    refreshed_at: str
    languages: dict[str, int] = Field(default_factory=dict)
    skills: list[GithubSkillEvidence] = Field(default_factory=list, max_length=100)
    repositories: list[GithubRepositoryEvidence] = Field(
        default_factory=list,
        max_length=20,
    )


class GithubProfileStatus(BaseModel):
    configured: bool
    connected: bool
    profile: GithubProfileEvidence | None = None
    message: str | None = None


class GithubDeviceAuthorization(BaseModel):
    user_code: str
    verification_uri: str
    expires_in: int = Field(gt=0)
    interval: int = Field(gt=0)


class GithubAuthorizationPoll(BaseModel):
    status: Literal[
        "pending",
        "slow_down",
        "connected",
        "expired",
        "denied",
    ]
    retry_after: int = Field(default=5, ge=1)
    profile: GithubProfileEvidence | None = None
    message: str | None = None


class GithubProfileMessage(BaseModel):
    message: str


class OpportunityPreferences(BaseModel):
    role_type: Literal["internship", "newgrad"] = "newgrad"
    timeframe: Literal["all", "lastday", "lastweek", "lastmonth"] = "all"
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
    locations: list[str]
    url: str
    source: str
    category: str | None = None
    posted_at: str | None = None
    updated_at: str | None = None
    sponsorship: str | None = None
    degrees: list[str] = Field(default_factory=list)
    company_profile_url: str | None = None
    company_logo_url: str | None = None
    active: bool = True
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
