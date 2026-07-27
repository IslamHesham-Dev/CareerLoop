"""A LangChain agent middleware that makes generated text sound like the student.

    from app.tone import ToneMiddleware, ToneProfile

    agent = create_agent(
        model=model,
        tools=[...],
        system_prompt=cv_generation_prompt,
        middleware=[ToneMiddleware(tone_profile)],
    )

That's the whole integration: one line in whichever agent's `middleware=[...]`
list, no changes to that agent's own prompt or tools. `wrap_model_call` runs
right before every model call and appends the student's writing-sample
reference to the system message, so it composes cleanly with any other
middleware already on the agent.
"""

from __future__ import annotations

from typing import Callable

from langchain.agents.middleware import AgentMiddleware
from langchain.agents.middleware.types import ModelRequest, ModelResponse
from langchain_core.messages import SystemMessage

from .models import ToneProfile
from .prompt import build_tone_reference


class ToneMiddleware(AgentMiddleware):
    """Appends a student's own writing samples to the system prompt."""

    def __init__(self, profile: ToneProfile) -> None:
        super().__init__()
        self._reference = build_tone_reference(profile)

    def wrap_model_call(
        self,
        request: ModelRequest,
        handler: Callable[[ModelRequest], ModelResponse],
    ) -> ModelResponse:
        if not self._reference:
            return handler(request)  # empty profile: safe no-op, nothing to add

        base = request.system_prompt or ""
        combined = SystemMessage(content=f"{base}\n\n{self._reference}".strip())
        return handler(request.override(system_message=combined))
