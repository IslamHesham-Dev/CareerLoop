from __future__ import annotations

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)


class ToolEvent(BaseModel):
    name: str
    status: str = "completed"


class PracticeQuestion(BaseModel):
    id: str
    question: str
    options: list[str]
    correct_index: int
    explanation: str
    concept: str


class PracticeSet(BaseModel):
    id: str
    title: str
    course: str
    assessment_type: str
    created_at: str
    study_notes: str
    questions: list[PracticeQuestion]


class ChatResponse(BaseModel):
    answer: str
    tools: list[ToolEvent]
    sources: list[str]
    practice_set: PracticeSet | None = None
