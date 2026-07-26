from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.agent.factory import PracticeQuestionInput, PracticeSetInput
from app.schemas.chat import ChatResponse


def _question(correct_index: int = 2) -> PracticeQuestionInput:
    return PracticeQuestionInput(
        question="Which operation has logarithmic complexity in a balanced BST?",
        options=["Traversal", "Linear scan", "Search", "Array append"],
        correct_index=correct_index,
        explanation="Balanced tree height is logarithmic, so search follows O(log n) levels.",
        concept="Balanced search trees",
    )


def test_practice_schema_preserves_the_correct_answer_mapping() -> None:
    practice = PracticeSetInput(
        title="Data Structures Midterm",
        course="CSEN301",
        assessment_type="midterm",
        study_notes="Review tree balance, height, and logarithmic search behavior.",
        questions=[_question() for _ in range(5)],
    )

    assert practice.questions[0].correct_index == 2
    assert practice.questions[0].options[2] == "Search"


def test_practice_question_rejects_an_invalid_answer_index() -> None:
    with pytest.raises(ValidationError):
        _question(correct_index=4)


def test_chat_response_can_carry_practice_separately_from_visible_answer() -> None:
    response = ChatResponse(
        answer="Your study notes and interactive practice set are ready.",
        tools=[],
        sources=["GIU CMS PDF"],
        practice_set={
            "id": "set-1",
            "title": "Data Structures Midterm",
            "course": "CSEN301",
            "assessment_type": "midterm",
            "created_at": "2026-07-26T12:00:00+00:00",
            "study_notes": "Review tree balance, height, and logarithmic search behavior.",
            "questions": [
                {
                    "id": "q-1",
                    **_question().model_dump(),
                }
            ],
        },
    )

    assert "Search" not in response.answer
    assert response.practice_set is not None
    assert response.practice_set.questions[0].correct_index == 2
