from langchain.agents.middleware.types import ModelRequest
from langchain_core.messages import SystemMessage

from app.tone import ToneMiddleware, ToneProfile, build_tone_reference


def _request(system_text: str) -> ModelRequest:
    return ModelRequest(
        model=None,
        messages=[],
        system_message=SystemMessage(content=system_text),
        tool_choice=None,
        tools=[],
        response_format=None,
        state={},
        runtime=None,
    )


def test_build_tone_reference_includes_each_answer_and_the_guardrail() -> None:
    profile = ToneProfile(
        answers={
            "Introduce yourself.": "I like building things that break less often.",
            "Describe a project.": "Shipped a scraper that finally stopped 500ing.",
        }
    )

    reference = build_tone_reference(profile)

    assert "I like building things that break less often." in reference
    assert "Shipped a scraper that finally stopped 500ing." in reference
    assert "never copy their sentences into generated output verbatim" in reference


def test_build_tone_reference_is_empty_for_a_profile_with_no_answers() -> None:
    assert build_tone_reference(ToneProfile()) == ""


def test_build_tone_reference_skips_blank_answers() -> None:
    profile = ToneProfile(answers={"Q1": "   ", "Q2": "A real answer."})

    reference = build_tone_reference(profile)

    assert "Q1" not in reference
    assert "A real answer." in reference


def test_tone_middleware_appends_reference_to_the_system_message() -> None:
    profile = ToneProfile(answers={"Q": "I write short, direct sentences."})
    middleware = ToneMiddleware(profile)
    request = _request("You are the CV-writing agent.")
    captured: list[ModelRequest] = []

    def handler(sent_request: ModelRequest) -> str:
        captured.append(sent_request)
        return "ok"

    result = middleware.wrap_model_call(request, handler)

    assert result == "ok"
    assert len(captured) == 1
    final_prompt = captured[0].system_prompt
    assert final_prompt.startswith("You are the CV-writing agent.")
    assert "I write short, direct sentences." in final_prompt


def test_tone_middleware_is_a_no_op_for_an_empty_profile() -> None:
    middleware = ToneMiddleware(ToneProfile())
    request = _request("You are the CV-writing agent.")

    def handler(sent_request: ModelRequest) -> str:
        assert sent_request is request  # untouched, not even a copy
        return "ok"

    assert middleware.wrap_model_call(request, handler) == "ok"
