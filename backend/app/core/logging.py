"""structlog 셋업.

dev: 컬러 콘솔 (보기 좋음)
prod: JSON (집계/검색 가능)

사용:
    from app.core.logging import get_logger
    logger = get_logger(__name__)
    logger.info("user_created", user_id=str(uid), email=email)
"""

import logging
import sys

import structlog
from structlog.types import Processor

from app.core.config import get_settings


def setup_logging() -> None:
    """앱 부트스트랩 시점에 1회 호출. main.py에서."""
    settings = get_settings()

    shared_processors: list[Processor] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.StackInfoRenderer(),
    ]

    if settings.is_dev:
        renderer: Processor = structlog.dev.ConsoleRenderer(colors=True)
    else:
        renderer = structlog.processors.JSONRenderer()

    structlog.configure(
        processors=[
            *shared_processors,
            structlog.processors.format_exc_info,
            renderer,
        ],
        wrapper_class=structlog.make_filtering_bound_logger(getattr(logging, settings.log_level)),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(file=sys.stdout),
        cache_logger_on_first_use=True,
    )


def get_logger(name: str | None = None) -> structlog.stdlib.BoundLogger:
    """피처/서비스 코드에서 호출. `logger = get_logger(__name__)`."""
    return structlog.get_logger(name)
