from fastapi import APIRouter

from app.config import get_settings

router = APIRouter(tags=["system"])


@router.get("/health")
def health() -> dict[str, str]:
    settings = get_settings()
    provider = settings.llm_provider.strip().casefold()
    model = (
        settings.openrouter_model
        if provider == "openrouter"
        else settings.anthropic_model
    )
    return {
        "status": "ok",
        "service": settings.app_name,
        "environment": settings.environment,
        "llm_provider": provider,
        "llm_model": model,
    }
