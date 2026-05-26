"""F-XXX 기능명 — Pydantic 스키마 (API 입출력)."""

from uuid import UUID

from pydantic import BaseModel


class ExampleResponse(BaseModel):
    """GET /template/me 응답."""

    user_id: UUID
    display_name: str


# 예시 — POST 요청 바디
# class CreateItemRequest(BaseModel):
#     title: str
#     description: str | None = None
