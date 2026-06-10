"""character_states 에 드래그 위치 컬럼 추가 (PR-G2).

Revision ID: 0006_character_position
Revises: 0005_avatar_forge_schema
Create Date: 2026-06-09

작업 단위 #13 character — F-051 드래그 위치 영속화.

컬럼:
- position_x, position_y (double precision, nullable)
  flame world 좌표(logical). null = 미설정 → 모바일이 기본 위치 사용.

RLS: character_states 기존 정책(0004) 그대로. 컬럼 추가는 정책 무관.
팬 트리거 위치 저장은 service가 service role로 처리(기존 record_action과 동일).
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0006_character_position"
down_revision: str | Sequence[str] | None = "0005_avatar_forge_schema"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE character_states
            ADD COLUMN position_x double precision,
            ADD COLUMN position_y double precision;
        """
    )


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE character_states
            DROP COLUMN IF EXISTS position_x,
            DROP COLUMN IF EXISTS position_y;
        """
    )
