"""Provider-neutral construction for every CareerLoop language-model call."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from langchain_anthropic import ChatAnthropic
from langchain_openrouter import ChatOpenRouter

from app.config import Settings


class LlmConfigurationError(RuntimeError):
    """Raised when the selected model provider is missing valid settings."""


@dataclass(frozen=True)
class LlmRuntime:
    provider: str
    api_key: str
    model: str


def resolve_llm(settings: Settings) -> LlmRuntime:
    """Resolve and validate the selected provider without exposing its key."""
    provider = settings.llm_provider.strip().casefold()
    if provider == "openrouter":
        api_key = settings.openrouter_api_key.get_secret_value().strip()
        if not api_key:
            raise LlmConfigurationError(
                "OPENROUTER_API_KEY is not configured on the backend."
            )
        model = settings.openrouter_model.strip()
        if not model:
            raise LlmConfigurationError(
                "OPENROUTER_MODEL is not configured on the backend."
            )
        return LlmRuntime(provider=provider, api_key=api_key, model=model)
    if provider == "anthropic":
        api_key = settings.anthropic_api_key.get_secret_value().strip()
        if not api_key:
            raise LlmConfigurationError(
                "ANTHROPIC_API_KEY is not configured on the backend."
            )
        model = settings.anthropic_model.strip()
        if not model:
            raise LlmConfigurationError(
                "ANTHROPIC_MODEL is not configured on the backend."
            )
        return LlmRuntime(provider=provider, api_key=api_key, model=model)
    raise LlmConfigurationError(
        "LLM_PROVIDER must be either 'openrouter' or 'anthropic'."
    )


def build_chat_model(
    settings: Settings,
    *,
    temperature: float = 0,
    max_tokens: int | None = None,
) -> Any:
    runtime = resolve_llm(settings)
    return build_chat_model_for(
        provider=runtime.provider,
        api_key=runtime.api_key,
        model=runtime.model,
        temperature=temperature,
        max_tokens=max_tokens,
        app_url=settings.openrouter_app_url,
        app_title=settings.openrouter_app_title,
    )


def build_chat_model_for(
    *,
    provider: str,
    api_key: str,
    model: str,
    temperature: float = 0,
    max_tokens: int | None = None,
    app_url: str = "https://careerloop.onrender.com",
    app_title: str = "CareerLoop",
) -> Any:
    """Build a LangChain chat model for internal generators/connectors."""
    provider_name = provider.strip().casefold()
    common: dict[str, Any] = {
        "model": model,
        "temperature": temperature,
        "api_key": api_key,
    }
    if max_tokens is not None:
        common["max_tokens"] = max_tokens

    if provider_name == "openrouter":
        return ChatOpenRouter(
            **common,
            app_url=app_url or None,
            app_title=app_title or None,
            # Structured-output and tool calls must only route to endpoints
            # that support the request parameters CareerLoop sends.
            openrouter_provider={"require_parameters": True},
        )
    if provider_name == "anthropic":
        return ChatAnthropic(**common)
    raise LlmConfigurationError(
        "LLM provider must be either 'openrouter' or 'anthropic'."
    )
