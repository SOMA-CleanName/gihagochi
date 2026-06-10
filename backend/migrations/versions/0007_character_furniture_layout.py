"""character_states 에 가구 배치 컬럼 추가 (가구 편집 모드).

Revision ID: 0007_character_furniture_layout
Revises: 0006_character_position
Create Date: 2026-06-10

작업 단위 #13 character — 가구 편집 모드 (아이돌별 가구 배치, 모든 팬 공유).

컬럼:
- furniture_layout (jsonb, nullable)
  {kind: {x, y, w}} 형태. flame world 좌표(logical). null = 기본 배치(모바일 코드).
  아이돌 본인만 편집 (router에서 권한 체크).

RLS: character_states 기존 정책(0004) 그대로. 컬럼 추가는 정책 무관.
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0007_character_furniture_layout"
down_revision: str | Sequence[str] | None = "0006_character_position"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("ALTER TABLE character_states ADD COLUMN furniture_layout jsonb;")


def downgrade() -> None:
    op.execute("ALTER TABLE character_states DROP COLUMN IF EXISTS furniture_layout;")
