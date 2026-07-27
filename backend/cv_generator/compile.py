"""Best-effort LaTeX -> PDF compilation.

Compilation is optional by design: the guaranteed deliverable is always the
`.tex` source from `latex_template.render_latex` (pastable straight into
Overleaf). This module only adds a compiled PDF on top when a LaTeX engine
happens to be on PATH. `tectonic` is preferred — a single static binary that
fetches only the packages a document needs, not an 800MB+ texlive install —
with `pdflatex` as a fallback if a full TeX distribution already exists.
Neither is required for the feature to work; see `_find_engine`.
"""

from __future__ import annotations

import logging
import shutil
import subprocess
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)

_TIMEOUT_SECONDS = 40


def _find_engine() -> str | None:
    """The first available engine, preferring tectonic. None if neither is installed."""
    for candidate in ("tectonic", "pdflatex"):
        if shutil.which(candidate):
            return candidate
    return None


def _command_for(engine: str, tex_path: Path, out_dir: Path) -> list[str]:
    if engine == "tectonic":
        return ["tectonic", "--outdir", str(out_dir), str(tex_path)]
    # pdflatex: a single pass is enough - this template has no TOC, citations,
    # or cross-references that would need a second pass to resolve.
    return [
        "pdflatex",
        "-interaction=nonstopmode",
        "-halt-on-error",
        f"-output-directory={out_dir}",
        str(tex_path),
    ]


def compile_latex_to_pdf(tex_source: str) -> bytes | None:
    """Compile `tex_source` to PDF bytes, or None if compilation isn't possible.

    Never raises: a missing engine, a timeout, or a failed compile all
    degrade to None so the caller can fall back to returning the `.tex`
    source alone instead of failing the whole request.
    """
    engine = _find_engine()
    if engine is None:
        logger.info(
            "No LaTeX engine (tectonic/pdflatex) found on PATH; skipping PDF compile."
        )
        return None

    with tempfile.TemporaryDirectory(prefix="careerloop_cv_") as tmp_dir:
        tmp_path = Path(tmp_dir)
        tex_path = tmp_path / "cv.tex"
        tex_path.write_text(tex_source, encoding="utf-8")
        pdf_path = tmp_path / "cv.pdf"

        try:
            result = subprocess.run(
                _command_for(engine, tex_path, tmp_path),
                cwd=tmp_dir,
                capture_output=True,
                timeout=_TIMEOUT_SECONDS,
                text=True,
            )
        except (subprocess.TimeoutExpired, OSError) as exc:
            logger.warning("LaTeX compilation with %s failed to run: %s", engine, exc)
            return None

        if result.returncode != 0 or not pdf_path.exists():
            logger.warning(
                "LaTeX compilation with %s exited %s.\nstdout:\n%s\nstderr:\n%s",
                engine,
                result.returncode,
                result.stdout[-2000:],
                result.stderr[-2000:],
            )
            return None

        return pdf_path.read_bytes()
