# syntax=docker/dockerfile:1.7
#
# 멀티스테이지 빌드:
#  builder  — 의존성 설치 (apt build deps 포함)
#  runtime  — slim 이미지 + non-root 사용자 + venv 복사
#
# Railway/Render에서 PORT env 주입. shell form CMD로 ${PORT:-8000} 처리.

# ============================================================
# Stage 1: builder
# ============================================================
FROM python:3.13-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# build-essential: asyncpg/cryptography/grpcio 등 C 확장 빌드용
# libpq-dev: psycopg/asyncpg가 일부 환경에서 요구
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build

# pyproject.toml + app/ 통째로 복사 후 비-editable 설치.
# (editable 모드는 source path 필요. 컨테이너엔 baked-in 권장.)
COPY pyproject.toml ./
COPY app/ ./app/
RUN pip install --no-cache-dir .

# ============================================================
# Stage 2: runtime
# ============================================================
FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# 런타임 의존 (asyncpg는 빌드 시 정적 링크지만 libpq 일부 환경 필요)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 app

# builder에서 설치된 venv 복사
COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=app:app app/ ./app/

USER app

EXPOSE 8000

# 컨테이너 내부 healthcheck. Railway/Render는 별도 외부 헬스체크도 함.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/health').status == 200 else 1)" \
      || exit 1

# shell form: ${PORT:-8000} 확장. Railway/Render가 PORT 주입.
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
