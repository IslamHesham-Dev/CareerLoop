from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.concurrency import run_in_threadpool
from langchain_core.messages import HumanMessage

from app.agent.factory import (
    build_agent,
    message_text,
    tool_events,
)
from app.config import get_settings
from app.schemas.auth import MessageResponse
from app.schemas.chat import ChatRequest, ChatResponse
from app.sessions.models import StudentSession
from app.dependencies import get_student_session

router = APIRouter(prefix="/chat", tags=["advisor"])


def requires_practice_set(message: str) -> bool:
    normalized = " ".join(message.lower().split())
    has_practice_format = any(
        phrase in normalized
        for phrase in (
            "quiz",
            "mcq",
            "multiple choice",
            "practice question",
            "exam prep",
            "exam practice",
            "midterm prep",
            "midterm practice",
            "final prep",
            "final practice",
        )
    )
    has_creation_intent = any(
        phrase in normalized
        for phrase in (
            "create",
            "make",
            "generate",
            "prepare",
            "build",
            "practice",
            "quiz me",
            "test me",
            "give me",
            "i want",
        )
    )
    return has_practice_format and has_creation_intent


def practice_control_message(message: str) -> str:
    return (
        f"{message}\n\n"
        "[APPLICATION CONTROL — NOT USER-VISIBLE]\n"
        "This is an explicit interactive quiz request. After reading the "
        "necessary evidence, you must call create_practice_set in this turn. "
        "Put notes in study_notes and keep every question, option, answer, and "
        "explanation out of your visible response."
    )


@router.post("", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    student: StudentSession = Depends(get_student_session),
) -> ChatResponse:
    settings = get_settings()

    def invoke() -> ChatResponse:
        with student.chat_lock:
            if student.agent is None:
                student.agent = build_agent(student, settings)
            student.pending_practice_set = None
            start = len(student.conversation)
            user_message = payload.message.strip()
            needs_practice = requires_practice_set(user_message)
            result = student.agent.invoke(
                {
                    "messages": [
                        *student.conversation,
                        HumanMessage(
                            practice_control_message(user_message)
                            if needs_practice
                            else user_message
                        ),
                    ]
                }
            )
            student.conversation = result["messages"]
            if needs_practice and student.pending_practice_set is None:
                retry = student.agent.invoke(
                    {
                        "messages": [
                            *student.conversation,
                            HumanMessage(
                                "[APPLICATION CONTROL RETRY — NOT USER-VISIBLE] "
                                "The required create_practice_set tool was not "
                                "called. Reuse the evidence already gathered "
                                "and call it now. Do not print its contents."
                            ),
                        ]
                    }
                )
                student.conversation = retry["messages"]
            new_messages = student.conversation[start:]
            answer = message_text(student.conversation[-1].content)
            events, sources = tool_events(new_messages)
            if student.pending_practice_set is not None:
                notes = student.pending_practice_set["study_notes"].strip()
                answer = (
                    f"{notes}\n\n"
                    "Your interactive practice set is ready below."
                )
            return ChatResponse(
                answer=answer,
                tools=events,
                sources=sources,
                practice_set=student.pending_practice_set,
            )

    try:
        return await run_in_threadpool(invoke)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from None
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="CareerLoop Copilot could not complete this request.",
        ) from None


@router.post("/reset", response_model=MessageResponse)
def reset_chat(
    student: StudentSession = Depends(get_student_session),
) -> MessageResponse:
    with student.chat_lock:
        student.conversation.clear()
        student.pending_practice_set = None
    return MessageResponse(message="Advisory conversation reset.")
