from langchain_core.messages import ToolMessage

from app.agent.factory import tool_events


def test_tool_events_use_the_active_university_connector_name() -> None:
    message = ToolMessage(
        content='{"year": "2024-2025"}',
        tool_call_id="call-1",
        name="get_full_transcript",
    )

    events, sources = tool_events([message], "GUC")

    assert events == [
        {"name": "get_full_transcript", "status": "completed"}
    ]
    assert sources == ["GUC transcript"]
