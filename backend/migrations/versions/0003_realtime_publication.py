"""realtime publication — messages 테이블 supabase_realtime publication 추가.

Revision ID: 0003_realtime_publication
Revises: 0002_storage_rls
Create Date: 2026-05-27

dev DB 에는 이미 `ALTER PUBLICATION supabase_realtime ADD TABLE messages` 적용됨
(chat_message_core PR #41 작업 중). 본 마이그레이션은 staging/prod 재현용 캡처.

이게 없으면 F-018 broadcast (`messages` INSERT 이벤트 Realtime 구독) 가 작동 안 함.
chat_message / chat_room 카드 갱신 hook 도 같이 영향.

전제: Supabase Postgres 환경 (supabase_realtime publication 존재).
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0003_realtime_publication"
down_revision: str | Sequence[str] | None = "0002_storage_rls"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# =============================================================================
# upgrade
# =============================================================================


def upgrade() -> None:
    # 이미 publication 에 들어있으면 ALTER 가 에러 throw — DO 블록으로 멱등화.
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_publication_tables
                 WHERE pubname    = 'supabase_realtime'
                   AND schemaname = 'public'
                   AND tablename  = 'messages'
            ) THEN
                ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
            END IF;
        END
        $$;
        """
    )


# =============================================================================
# downgrade
# =============================================================================


def downgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM pg_publication_tables
                 WHERE pubname    = 'supabase_realtime'
                   AND schemaname = 'public'
                   AND tablename  = 'messages'
            ) THEN
                ALTER PUBLICATION supabase_realtime DROP TABLE public.messages;
            END IF;
        END
        $$;
        """
    )
