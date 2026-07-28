FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

ARG TARGETARCH
ARG TECTONIC_VERSION=0.16.9
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && case "${TARGETARCH:-amd64}" in \
         amd64) TECTONIC_ARCH="x86_64" ;; \
         arm64) TECTONIC_ARCH="aarch64" ;; \
         *) echo "Unsupported build architecture: ${TARGETARCH}" && exit 1 ;; \
       esac \
    && curl --proto '=https' --tlsv1.2 -fsSL \
       "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-${TECTONIC_ARCH}-unknown-linux-musl.tar.gz" \
       | tar -xz -C /usr/local/bin tectonic \
    && tectonic --version \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

COPY latex_warmup.tex /tmp/latex_warmup.tex
RUN tectonic --untrusted --outdir /tmp /tmp/latex_warmup.tex \
    || tectonic --untrusted --outdir /tmp /tmp/latex_warmup.tex \
    || tectonic --untrusted --outdir /tmp /tmp/latex_warmup.tex

COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-dev || uv sync --no-dev

COPY app ./app
COPY guc_cms ./guc_cms
COPY guc_portal ./guc_portal
COPY swelist_connector ./swelist_connector
COPY company_jobs_connector ./company_jobs_connector
COPY github_connector ./github_connector
COPY cv_connector ./cv_connector
COPY cv_generator ./cv_generator
COPY cover_letter_generator ./cover_letter_generator
COPY content ./content

EXPOSE 8000

# One worker is intentional while sessions live in process memory.
CMD ["sh", "-c", ".venv/bin/uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
