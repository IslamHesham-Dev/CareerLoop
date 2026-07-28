from fastapi import APIRouter

from app.config import get_settings

router = APIRouter(tags=["system"])


@router.get("/health")
def health() -> dict[str, str]:
    settings = get_settings()
    provider = settings.llm_provider.strip().casefold()
    if provider in {"litellm", "ihq", "ihq-litellm"}:
        provider = "litellm"
        model = settings.litellm_model
    elif provider == "openrouter":
        model = settings.openrouter_model
    else:
        model = settings.anthropic_model
    return {
        "status": "ok",
        "service": settings.app_name,
        "environment": settings.environment,
        "llm_provider": provider,
        "llm_model": model,
    }
