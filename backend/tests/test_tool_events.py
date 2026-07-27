from types import SimpleNamespace

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


def test_job_search_discloses_connected_profile_evidence() -> None:
    message = SimpleNamespace(
        type="tool",
        name="search_tech_jobs",
        content=(
            '{"evidence":{"academic_transcript":true,'
            '"linkedin_pdf":true,"github":true}}'
        ),
    )

    _events, sources = tool_events([message], "GIU")

    assert "Swelist live jobs" in sources
    assert "Coursera course catalogue" in sources
    assert "GIU transcript" in sources
    assert "Imported LinkedIn profile PDF" in sources
    assert "Connected GitHub project evidence" in sources
