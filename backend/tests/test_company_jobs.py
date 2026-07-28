from __future__ import annotations

import pytest

from company_jobs_connector.client import CompanyJobsConnector


def _connector() -> CompanyJobsConnector:
    return CompanyJobsConnector(anthropic_api_key="dummy-not-used-in-these-tests")


def test_model_is_configurable_instead_of_hardcoded_to_a_legacy_model() -> None:
    connector = CompanyJobsConnector(
        anthropic_api_key="dummy", model="claude-haiku-4-5"
    )

    assert connector.llm.model == "claude-haiku-4-5"


def test_looks_like_a_careers_page_rejects_an_empty_js_shell() -> None:
    # This is the real shape of the false positive found in manual testing:
    # an Ashby board for a company slug with no real listings behind it
    # returns a full HTML document, but the rendered text is just "Jobs".
    shell_html = "<html><body><div id='app'></div><script>/* big JS bundle */</script></body></html>"
    connector = _connector()

    assert connector._looks_like_a_careers_page(shell_html) is False


def test_looks_like_a_careers_page_accepts_real_listing_text() -> None:
    real_html = (
        "<html><body>"
        "<h1>Acme Careers</h1>"
        + "<p>Software Engineer - Remote - Apply now.</p>" * 5
        + "</body></html>"
    )
    connector = _connector()

    assert connector._looks_like_a_careers_page(real_html) is True


def test_discover_careers_url_rejects_an_empty_ats_shell(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Reproduces the live false positive: boards.greenhouse.io/acme (the
    first candidate tried) looks real; jobs.ashbyhq.com would have been an
    empty shell, but greenhouse succeeds first so it's never reached."""

    class Response:
        ok = True
        # Must clear the fallback loop's raw-HTML size guard (> 1000 bytes)
        # in addition to the rendered-text check this test targets.
        text = (
            "<html><body>"
            + "<p>Software Engineer - Remote - Apply now.</p>" * 30
            + "</body></html>"
        )

    def fake_get(url, timeout=None, headers=None):
        return Response()

    monkeypatch.setattr("company_jobs_connector.client.requests.get", fake_get)
    connector = _connector()

    assert connector._discover_careers_url("Acme") == "https://boards.greenhouse.io/acme"


def test_discover_careers_url_returns_none_when_every_candidate_is_an_empty_shell(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    class EmptyShellResponse:
        ok = True
        text = "<html><body><div id='app'></div></body></html>"

    def fake_get(url, timeout=None, headers=None):
        return EmptyShellResponse()

    monkeypatch.setattr("company_jobs_connector.client.requests.get", fake_get)
    connector = _connector()

    assert connector._discover_careers_url("Ghost Corp") is None


def test_discover_careers_url_falls_through_when_serper_result_is_empty(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A Serper search hit that turns out to be a dead/empty page must not be
    trusted blindly - it should fall through to the ATS-guessing fallback."""

    class SerperResponse:
        ok = True

        @staticmethod
        def json():
            return {"organic": [{"link": "https://example.com/stale-listing"}]}

    class EmptyPageResponse:
        ok = True
        text = "<html><body>Page not found</body></html>"

    class RealFallbackResponse:
        ok = True
        text = (
            "<html><body>"
            + "<p>Backend Engineer - Remote - Apply now.</p>" * 30
            + "</body></html>"
        )

    def fake_post(url, headers=None, json=None, timeout=None):
        return SerperResponse()

    def fake_get(url, timeout=None, headers=None):
        if url == "https://example.com/stale-listing":
            return EmptyPageResponse()
        return RealFallbackResponse()

    monkeypatch.setattr("company_jobs_connector.client.requests.post", fake_post)
    monkeypatch.setattr("company_jobs_connector.client.requests.get", fake_get)
    connector = CompanyJobsConnector(
        anthropic_api_key="dummy", serper_api_key="dummy-serper-key"
    )

    assert (
        connector._discover_careers_url("Acme")
        == "https://boards.greenhouse.io/acme"
    )
