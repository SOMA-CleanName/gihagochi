"""character_states + character_action_logs 테이블 + character_action_type ENUM + RLS.

Revision ID: 0004_character_states
Revises: 0003_realtime_publication
Create Date: 2026-05-30

작업 단위 #13 character (F-042 상태 DB + F-043 행동 트리거 IF).

테이블:
- character_states: 아이돌별 캐릭터 현재 상태 1:1 (idol_id UNIQUE)
- character_action_logs: 캐릭터 행동 트리거 이력 (append-only)

ENUM:
- character_action_type: idle / happy / sad / sing / eat / sleep
  (mobile features/character/domain의 enum과 1:1 매핑)

RLS:
- character_states: 본인(아이돌) read/update + 공개 read (구독자/탐색용)
- character_action_logs: 본인(아이돌) read + 본인 row INSERT + 공개 read 가능

전제: Supabase Postgres + profiles 테이블 존재 (0001_initial).
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0004_character_states"
down_revision: str | Sequence[str] | None = "0003_realtime_publication"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# =============================================================================
# upgrade
# =============================================================================


def upgrade() -> None:
    # 1. ENUM 타입
    op.execute(
        """
        CREATE TYPE character_action_type AS ENUM
            ('idle', 'happy', 'sad', 'sing', 'eat', 'sleep');
        """
    )

    # 2. character_states 테이블
    op.execute(
        """
        CREATE TABLE character_states (
            id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            idol_id       uuid NOT NULL UNIQUE
                          REFERENCES profiles(id) ON DELETE CASCADE,
            current_action character_action_type NOT NULL DEFAULT 'idle',
            hunger        smallint NOT NULL DEFAULT 100 CHECK (hunger BETWEEN 0 AND 100),
            happiness     smallint NOT NULL DEFAULT 100 CHECK (happiness BETWEEN 0 AND 100),
            energy        smallint NOT NULL DEFAULT 100 CHECK (energy BETWEEN 0 AND 100),
            updated_at    timestamptz NOT NULL DEFAULT NOW(),
            created_at    timestamptz NOT NULL DEFAULT NOW()
        );
        """
    )

    # updated_at 자동 갱신 트리거 (0001_initial의 set_updated_at 함수 재사용)
    op.execute(
        """
        CREATE TRIGGER trg_character_states_updated_at
        BEFORE UPDATE ON character_states
        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
        """
    )

    # 3. character_action_logs 테이블
    op.execute(
        """
        CREATE TABLE character_action_logs (
            id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            idol_id       uuid NOT NULL
                          REFERENCES profiles(id) ON DELETE CASCADE,
            action        character_action_type NOT NULL,
            performed_by  uuid
                          REFERENCES profiles(id) ON DELETE SET NULL,
            performed_at  timestamptz NOT NULL DEFAULT NOW()
        );
        """
    )
    op.execute(
        "CREATE INDEX character_action_logs_idol_id_performed_at_idx "
        "ON character_action_logs (idol_id, performed_at DESC);"
    )

    # 4. RLS — character_states
    op.execute(
        """
        ALTER TABLE character_states ENABLE ROW LEVEL SECURITY;

        -- 누구나 read (활성 아이돌의 캐릭터 상태는 공개)
        CREATE POLICY character_states_select_public
            ON character_states FOR SELECT
            USING (true);

        -- 본인(아이돌)만 자기 row INSERT
        CREATE POLICY character_states_insert_self
            ON character_states FOR INSERT
            WITH CHECK (auth.uid() = idol_id);

        -- 본인(아이돌)만 자기 row UPDATE
        CREATE POLICY character_states_update_self
            ON character_states FOR UPDATE
            USING (auth.uid() = idol_id)
            WITH CHECK (auth.uid() = idol_id);
        """
    )

    # 5. RLS — character_action_logs
    op.execute(
        """
        ALTER TABLE character_action_logs ENABLE ROW LEVEL SECURITY;

        -- 누구나 read (활성 아이돌의 행동 로그는 공개)
        CREATE POLICY character_action_logs_select_public
            ON character_action_logs FOR SELECT
            USING (true);

        -- 본인(아이돌)이 자기 행동 INSERT (팬 트리거는 service role로 backend가 처리)
        CREATE POLICY character_action_logs_insert_self
            ON character_action_logs FOR INSERT
            WITH CHECK (auth.uid() = idol_id);
        """
    )


# =============================================================================
# downgrade
# =============================================================================


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS character_action_logs;")
    op.execute("DROP TABLE IF EXISTS character_states;")
    op.execute("DROP TYPE IF EXISTS character_action_type;")
