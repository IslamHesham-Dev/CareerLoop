from __future__ import annotations

import os
from pathlib import Path

from print_jobs import load_env_file


def test_load_env_file_populates_environment(tmp_path, monkeypatch) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text("ANTHROPIC_API_KEY=from-test\n", encoding="utf-8")

    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    loaded_path = load_env_file(env_path)

    assert loaded_path == env_path
    assert os.environ["ANTHROPIC_API_KEY"] == "from-test"
