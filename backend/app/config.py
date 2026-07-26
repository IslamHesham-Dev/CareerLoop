from __future__ import annotations

from functools import lru_cache

from pydantic import AliasChoices, Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration sourced only from the backend environment."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
        env_prefix="DEGREELENS_",
    )

    app_name: str = "CareerLoop API"
    environment: str = "development"
    debug: bool = False
    anthropic_api_key: SecretStr = Field(
        default=SecretStr(""),
        validation_alias="ANTHROPIC_API_KEY",
    )
    anthropic_model: str = Field(
        default="claude-haiku-4-5",
        validation_alias="ANTHROPIC_MODEL",
    )
    notion_api_key: SecretStr = Field(
        default=SecretStr(""),
        validation_alias=AliasChoices(
            "NOTION_API_KEY",
            "NOTION_TOKEN",
            "NOTION_INTEGRATION_TOKEN",
            "DEGREELENS_NOTION_API_KEY",
        ),
    )
    notion_parent_page_id: str = Field(
        default="",
        validation_alias=AliasChoices(
            "NOTION_PARENT_PAGE_ID",
            "NOTION_PAGE_ID",
            "DEGREELENS_NOTION_PARENT_PAGE_ID",
        ),
    )
    notion_oauth_client_id: str = Field(
        default="",
        validation_alias=AliasChoices(
            "NOTION_OAUTH_CLIENT_ID",
            "DEGREELENS_NOTION_OAUTH_CLIENT_ID",
        ),
    )
    notion_oauth_client_secret: SecretStr = Field(
        default=SecretStr(""),
        validation_alias=AliasChoices(
            "NOTION_OAUTH_CLIENT_SECRET",
            "DEGREELENS_NOTION_OAUTH_CLIENT_SECRET",
        ),
    )
    notion_oauth_redirect_uri: str = Field(
        default="",
        validation_alias=AliasChoices(
            "NOTION_OAUTH_REDIRECT_URI",
            "DEGREELENS_NOTION_OAUTH_REDIRECT_URI",
        ),
    )
    notion_api_version: str = Field(
        default="2026-03-11",
        validation_alias=AliasChoices(
            "NOTION_API_VERSION",
            "DEGREELENS_NOTION_API_VERSION",
        ),
    )
    session_ttl_minutes: int = 45
    advisory_year: str = "2024-2025"
    current_season: str = "Winter 2024"
    cors_origins: str = (
        "http://localhost,http://localhost:3000,http://localhost:8080,"
        "http://127.0.0.1:3000,http://127.0.0.1:8080"
    )

    @property
    def allowed_origins(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.cors_origins.split(",")
            if origin.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()
