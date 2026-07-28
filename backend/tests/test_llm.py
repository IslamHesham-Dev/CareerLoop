from langchain_openrouter import ChatOpenRouter

from app.config import Settings
from app.llm import build_chat_model, resolve_llm


def test_openrouter_settings_select_fixed_free_gemma() -> None:
    settings = Settings(
        _env_file=None,
        LLM_PROVIDER="openrouter",
        OPENROUTER_API_KEY="test-openrouter-key",
        OPENROUTER_MODEL="google/gemma-4-31b-it:free",
    )

    runtime = resolve_llm(settings)
    model = build_chat_model(settings)

    assert runtime.provider == "openrouter"
    assert runtime.model == "google/gemma-4-31b-it:free"
    assert isinstance(model, ChatOpenRouter)
    assert model.model_name == "google/gemma-4-31b-it:free"
    assert model.openrouter_provider == {"require_parameters": True}
