"""표준 에러 응답 + Sentry 캡처.

응답 shape:
    {
        "error": {
            "code": "snake_case_id",
            "message": "사람용 메시지",
            "details": {...} | null
        }
    }

사용:
    from app.core.errors import NotFoundError
    raise NotFoundError("아이돌을 찾을 수 없습니다.")

main.py에서 `register_error_handlers(app)` 호출 필수.
"""

from typing import Any

import sentry_sdk
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class AppError(Exception):
    """애플리케이션 에러 베이스. 모든 비즈니스 에러는 이 클래스 상속."""

    status_code: int = 500
    code: str = "internal_error"
    message: str = "내부 오류가 발생했습니다."

    def __init__(
        self,
        message: str | None = None,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(message or self.message)
        if message:
            self.message = message
        self.details = details


class NotFoundError(AppError):
    status_code = 404
    code = "not_found"
    message = "리소스를 찾을 수 없습니다."


class UnauthorizedError(AppError):
    status_code = 401
    code = "unauthorized"
    message = "인증이 필요합니다."


class ForbiddenError(AppError):
    status_code = 403
    code = "forbidden"
    message = "권한이 없습니다."


class ConflictError(AppError):
    status_code = 409
    code = "conflict"
    message = "리소스 충돌이 발생했습니다."


class ValidationError(AppError):
    status_code = 422
    code = "validation_error"
    message = "입력값이 올바르지 않습니다."


def _error_response(
    status_code: int,
    code: str,
    message: str,
    details: dict[str, Any] | None = None,
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "error": {
                "code": code,
                "message": message,
                "details": details,
            }
        },
    )


def register_error_handlers(app: FastAPI) -> None:
    """main.py 부트스트랩 시 호출. 표준 핸들러 등록 + Sentry 자동 캡처."""

    @app.exception_handler(AppError)
    async def app_error_handler(_: Request, exc: AppError) -> JSONResponse:
        if exc.status_code >= 500:
            sentry_sdk.capture_exception(exc)
        return _error_response(exc.status_code, exc.code, exc.message, exc.details)

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        return _error_response(
            exc.status_code,
            f"http_{exc.status_code}",
            str(exc.detail),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        _: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return _error_response(
            422,
            "validation_error",
            "입력값이 올바르지 않습니다.",
            {"errors": exc.errors()},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(_: Request, exc: Exception) -> JSONResponse:
        sentry_sdk.capture_exception(exc)
        return _error_response(500, "internal_error", "내부 오류가 발생했습니다.")
