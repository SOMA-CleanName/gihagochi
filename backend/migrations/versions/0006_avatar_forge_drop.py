"""Avatar Forge 스키마 폐기: 0005 객체 모두 DROP.

Revision ID: 0006_avatar_forge_drop
Revises: 0005_avatar_forge_schema
Create Date: 2026-06-08

2026-06-08 결정: PoC 결과 + flame 채택으로 Avatar Forge 부품 시스템 불필요.
0005에서 만든 모든 객체 제거. 검증 SQL은 0005 머지 직후 통과 완료.

DROP 순서 (의존 역순):
1. 트리거 2 (테이블 의존)
2. 함수 1 (validate_slot_state_keys — slot_state 전용)
3. 테이블 3 (FK 역순: inventory → slot_state → parts)
4. ENUM 1 (테이블 다 정리 후)

set_updated_at 함수는 0001 정의분 그대로 — character_states가 공유하므로 DROP X.

downgrade: 0005 그대로 재현 (정확히 0005 upgrade와 동일).
단 PoC 폐기 결정으로 downgrade 실수행 권장 X.
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0006_avatar_forge_drop"
down_revision: str | Sequence[str] | None = "0005_avatar_forge_schema"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# =============================================================================
# upgrade — 0005 객체 모두 DROP
# =============================================================================


def upgrade() -> None:
    # 1. 트리거 drop (테이블 의존)
    op.execute(
        "DROP TRIGGER IF EXISTS trg_validate_slot_state_keys "
        "ON idol_character_slot_state;"
    )
    op.execute(
        "DROP TRIGGER IF EXISTS trg_slot_state_updated_at "
        "ON idol_character_slot_state;"
    )

    # 2. 함수 drop — slot_state 전용. set_updated_at은 character_states가 쓰니까 DROP X
    op.execute("DROP FUNCTION IF EXISTS validate_slot_state_keys();")

    # 3. 테이블 drop — FK 역순
    op.execute("DROP TABLE IF EXISTS idol_part_inventory;")
    op.execute("DROP TABLE IF EXISTS idol_character_slot_state;")
    op.execute("DROP TABLE IF EXISTS character_parts;")

    # 4. ENUM drop — 테이블 다 정리 후
    op.execute("DROP TYPE IF EXISTS character_part_category;")


# =============================================================================
# downgrade — 0005 그대로 재현 (PoC 폐기 결정상 실수행 권장 X)
# =============================================================================


def downgrade() -> None:
    # 1. ENUM
    op.execute(
        """
        CREATE TYPE character_part_category AS ENUM
            ('head', 'eyes', 'mouth', 'top', 'bottom', 'shoes', 'accessory');
        """
    )

    # 2. character_parts
    op.execute(
        """
        CREATE TABLE character_parts (
            id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            category    character_part_category NOT NULL,
            asset_path  text NOT NULL,
            z_index     int NOT NULL,
            anchor_x    int NOT NULL,
            anchor_y    int NOT NULL,
            rarity      text NOT NULL DEFAULT 'common'
                        CHECK (rarity IN ('common', 'rare', 'epic')),
            tags        text[] DEFAULT '{}',
            created_at  timestamptz NOT NULL DEFAULT NOW()
        );
        """
    )
    op.execute(
        "CREATE INDEX character_parts_category_idx ON character_parts (category);"
    )

    # 3. idol_character_slot_state
    op.execute(
        """
        CREATE TABLE idol_character_slot_state (
            idol_id     uuid PRIMARY KEY
                        REFERENCES profiles(id) ON DELETE CASCADE,
            slots       jsonb NOT NULL DEFAULT '{}'::jsonb,
            updated_at  timestamptz NOT NULL DEFAULT NOW()
        );
        """
    )
    op.execute(
        "CREATE INDEX idol_character_slot_state_slots_gin_idx "
        "ON idol_character_slot_state USING gin (slots);"
    )

    # 4. validate_slot_state_keys 함수 + 트리거
    op.execute(
        """
        CREATE OR REPLACE FUNCTION validate_slot_state_keys()
        RETURNS TRIGGER AS $$
        DECLARE
            invalid_key text;
        BEGIN
            SELECT key INTO invalid_key
            FROM jsonb_object_keys(NEW.slots) AS key
            WHERE key NOT IN (
                SELECT unnest(enum_range(NULL::character_part_category))::text
            )
            LIMIT 1;

            IF invalid_key IS NOT NULL THEN
                RAISE EXCEPTION 'invalid slot key: %, allowed: %',
                    invalid_key,
                    enum_range(NULL::character_part_category)::text;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        """
    )
    op.execute(
        """
        CREATE TRIGGER trg_validate_slot_state_keys
            BEFORE INSERT OR UPDATE ON idol_character_slot_state
            FOR EACH ROW EXECUTE FUNCTION validate_slot_state_keys();
        """
    )

    # 5. updated_at 자동 갱신 트리거 (set_updated_at 재사용)
    op.execute(
        """
        CREATE TRIGGER trg_slot_state_updated_at
            BEFORE UPDATE ON idol_character_slot_state
            FOR EACH ROW EXECUTE FUNCTION set_updated_at();
        """
    )

    # 6. idol_part_inventory
    op.execute(
        """
        CREATE TABLE idol_part_inventory (
            idol_id           uuid NOT NULL
                              REFERENCES profiles(id) ON DELETE CASCADE,
            part_id           uuid NOT NULL
                              REFERENCES character_parts(id) ON DELETE RESTRICT,
            source            text NOT NULL DEFAULT 'default'
                              CHECK (source IN ('default', 'gift')),
            acquired_at       timestamptz NOT NULL DEFAULT NOW(),
            gift_from_fan_id  uuid NULL
                              REFERENCES profiles(id) ON DELETE SET NULL,

            PRIMARY KEY (idol_id, part_id),

            CONSTRAINT inventory_source_gift_consistency CHECK (
                (source = 'default' AND gift_from_fan_id IS NULL) OR
                (source = 'gift' AND gift_from_fan_id IS NOT NULL)
            )
        );
        """
    )

    # 7. RLS — character_parts
    op.execute(
        """
        ALTER TABLE character_parts ENABLE ROW LEVEL SECURITY;
        CREATE POLICY character_parts_select_public
            ON character_parts FOR SELECT USING (true);
        """
    )

    # 8. RLS — idol_character_slot_state
    op.execute(
        """
        ALTER TABLE idol_character_slot_state ENABLE ROW LEVEL SECURITY;
        CREATE POLICY slot_state_select_public
            ON idol_character_slot_state FOR SELECT USING (true);
        CREATE POLICY slot_state_insert_self
            ON idol_character_slot_state FOR INSERT
            WITH CHECK (auth.uid() = idol_id);
        CREATE POLICY slot_state_update_self
            ON idol_character_slot_state FOR UPDATE
            USING (auth.uid() = idol_id)
            WITH CHECK (auth.uid() = idol_id);
        """
    )

    # 9. RLS — idol_part_inventory
    op.execute(
        """
        ALTER TABLE idol_part_inventory ENABLE ROW LEVEL SECURITY;
        CREATE POLICY inventory_select_self
            ON idol_part_inventory FOR SELECT
            USING (auth.uid() = idol_id);
        """
    )
