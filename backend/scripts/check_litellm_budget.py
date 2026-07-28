"""Print the iHQ LiteLLM budget without exposing the API key."""

from __future__ import annotations

import json
import os
from decimal import Decimal
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from dotenv import load_dotenv


def main() -> None:
    load_dotenv()
    api_key = os.environ.get("LITELLM_API_KEY", "").strip()
    if not api_key:
        raise SystemExit(
            "LITELLM_API_KEY is missing. Add it to backend/.env or the "
            "current shell environment."
        )

    request = Request(
        "https://litellm.i-hq.tech/key/info",
        headers={"Authorization": f"Bearer {api_key}"},
    )
    try:
        with urlopen(request, timeout=15) as response:
            payload = json.load(response)
    except HTTPError as exc:
        raise SystemExit(
            f"LiteLLM returned HTTP {exc.code}; verify the assigned key."
        ) from exc
    except URLError as exc:
        raise SystemExit(f"Could not reach LiteLLM: {exc.reason}") from exc

    # LiteLLM deployments may wrap key information in an `info` object. Some
    # variants use `key` for either metadata or the (redacted) key string.
    info = payload.get("info")
    if not isinstance(info, dict):
        key_info = payload.get("key")
        info = key_info if isinstance(key_info, dict) else payload
    spend = Decimal(str(info.get("spend", 0)))
    maximum = Decimal(str(info.get("max_budget", 3)))
    remaining = max(Decimal("0"), maximum - spend)

    print(f"Spent:     ${spend:.4f}")
    print(f"Budget:    ${maximum:.4f}")
    print(f"Remaining: ${remaining:.4f}")


if __name__ == "__main__":
    main()
