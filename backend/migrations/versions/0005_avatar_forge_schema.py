"""Avatar Forge 스키마: character_part_category ENUM + character_parts + idol_character_slot_state + idol_part_inventory + RLS.

Revision ID: 0005_avatar_forge_schema
Revises: 0004_character_states
Create Date: 2026-06-04

작업 단위 #13 character — Avatar Forge (F-050/F-051/F-052 스키마 기반).

테이블:
- character_parts: 글로벌 부품 카탈로그 (운영/admin이 관리)
- idol_character_slot_state: 아이돌별 현재 슬롯 상태 (JSONB slots)
- idol_part_inventory: 아이돌별 보유 부품 (default 지급 / v2.1 gift)

ENUM:
- character_part_category: head / eyes / mouth / top / bottom / shoes / accessory
  character_parts.category 컬럼 + validate_slot_state_keys() 트리거 양쪽이 동일 ENUM 참조
  → 카테고리 추가 시 `ALTER TYPE ... ADD VALUE` 한 줄로 sync 자동 (단 같은 트랜잭션 내 사용 불가, PG 제약)

트리거:
- validate_slot_state_keys: idol_character_slot_state.slots JSONB 키 화이트리스트 검증 (BEFORE INSERT/UPDATE)
  PG는 CHECK constraint 안에 subquery/set-returning function 금지 → TRIGGER로 대체
  enum_range()로 ENUM 값 동적 참조 → ENUM 변경 시 함수 변경 불필요
- trg_slot_state_updated_at: updated_at 자동 갱신 (0001_initial의 set_updated_at 재사용)

RLS:
- character_parts: 공개 read + service role/admin 전용 write
- idol_character_slot_state: 공개 read (다마고치 본질, 아이돌 공개 정체성) + 본인 INSERT/UPDATE
- idol_part_inventory: 본인 read만 (사적 영역) + service role 전용 write/update

전제:
- 0001_initial: pgcrypto extension, profiles 테이블, set_updated_at() 함수 정의 (재사용)
- 시드 데이터는 본 마이그에 포함 X — PR-6 application 영역에서 처리

application 책임 (PR-6/9):
- gift_from_fan_id가 가리키는 profile의 role='fan' 검증 → service layer
- 중복 보유 시 source 업그레이드 UPSERT (default → gift) → service layer
- slots JSONB 내부 part_id 값이 character_parts.id에 실제 존재하는지 검증 (JSONB FK 불가)
"""

from __future__ import annotations

from collections.abc import Sequence

from alembic import op

# revision identifiers
revision: str = "0005_avatar_forge_schema"
down_revision: str | Sequence[str] | None = "0004_character_states"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# =============================================================================
# upgrade
# =============================================================================


def upgrade() -> None:
    # 1. ENUM — character_parts.category + validate_slot_state_keys() 트리거 양쪽이 참조
    op.execute(
        """
        CREATE TYPE character_part_category AS ENUM
            ('head', 'eyes', 'mouth', 'top', 'bottom', 'shoes', 'accessory');
        """
    )

    # 2. character_parts — 글로벌 부품 카탈로그
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

    # 3. idol_character_slot_state — 아이돌별 현재 슬롯 (JSONB)
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

    # GIN 인덱스 — v2.1+ JSONB 쿼리 대비
    op.execute(
        "CREATE INDEX idol_character_slot_state_slots_gin_idx "
        "ON idol_character_slot_state USING gin (slots);"
    )

    # slots JSONB 키 화이트리스트 검증 함수
    # PG는 CHECK constraint 안에 subquery/set-returning function 금지 → TRIGGER로 처리
    # enum_range()로 ENUM 값 동적 참조 → ENUM 추가 시 함수 변경 불필요
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

    # updated_at 자동 갱신 트리거 — 0001_initial의 set_updated_at 함수 재사용
    op.execute(
        """
        CREATE TRIGGER trg_slot_state_updated_at
            BEFORE UPDATE ON idol_character_slot_state
            FOR EACH ROW EXECUTE FUNCTION set_updated_at();
        """
    )

    # 4. idol_part_inventory — 아이돌별 보유 부품
    # PK = (idol_id, part_id) → 중복 보유 불가 (source 업그레이드는 UPSERT, PR-6 책임)
    # character_parts ON DELETE RESTRICT — 운영이 부품 삭제 시도 자체 차단
    # gift_from_fan_id ON DELETE SET NULL — 팬 탈퇴 시 인벤토리는 유지, 출처만 익명화
    # idol_part_inventory(idol_id) 단독 인덱스는 생성 X — PK leftmost prefix로 idol_id 단독 쿼리 자동 지원
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

    # 5. RLS — character_parts (글로벌 카탈로그, 공개)
    op.execute(
        """
        ALTER TABLE character_parts ENABLE ROW LEVEL SECURITY;

        -- 모든 사용자 read (메이커 부품 그리드)
        CREATE POLICY character_parts_select_public
            ON character_parts FOR SELECT
            USING (true);

        -- INSERT/UPDATE/DELETE는 service role/admin 전용 (RLS 정책 미생성으로 일반 user 차단)
        """
    )

    # 6. RLS — idol_character_slot_state (현재 캐릭터, 공개 정체성)
    op.execute(
        """
        ALTER TABLE idol_character_slot_state ENABLE ROW LEVEL SECURITY;

        -- 누구나 read (다마고치 본질 = 아이돌 공개 정체성. 응원 관계 체크는 F-016에서 이미 막음)
        CREATE POLICY slot_state_select_public
            ON idol_character_slot_state FOR SELECT
            USING (true);

        -- 본인(아이돌)만 자기 row INSERT
        CREATE POLICY slot_state_insert_self
            ON idol_character_slot_state FOR INSERT
            WITH CHECK (auth.uid() = idol_id);

        -- 본인(아이돌)만 자기 row UPDATE
        CREATE POLICY slot_state_update_self
            ON idol_character_slot_state FOR UPDATE
            USING (auth.uid() = idol_id)
            WITH CHECK (auth.uid() = idol_id);
        """
    )

    # 7. RLS — idol_part_inventory (사적 영역)
    op.execute(
        """
        ALTER TABLE idol_part_inventory ENABLE ROW LEVEL SECURITY;

        -- 본인만 read (어떤 부품 가졌는지는 본인만 알아야 함)
        CREATE POLICY inventory_select_self
            ON idol_part_inventory FOR SELECT
            USING (auth.uid() = idol_id);

        -- INSERT/UPDATE는 service role 전용 (MVP는 default 지급, v2.1은 gift 추가)
        -- 일반 user 직접 INSERT/UPDATE는 RLS 정책 미생성으로 차단
        """
    )


# =============================================================================
# downgrade
# =============================================================================


def downgrade() -> None:
    # 트리거 drop (테이블 의존)
    op.execute(
        "DROP TRIGGER IF EXISTS trg_validate_slot_state_keys "
        "ON idol_character_slot_state;"
    )
    op.execute(
        "DROP TRIGGER IF EXISTS trg_slot_state_updated_at "
        "ON idol_character_slot_state;"
    )

    # 함수 drop — slot_state 전용. set_updated_at은 character_states가 쓰니까 DROP X
    op.execute("DROP FUNCTION IF EXISTS validate_slot_state_keys();")

    # 테이블 drop — FK 역순
    op.execute("DROP TABLE IF EXISTS idol_part_inventory;")
    op.execute("DROP TABLE IF EXISTS idol_character_slot_state;")
    op.execute("DROP TABLE IF EXISTS character_parts;")

    # ENUM drop — 테이블 다 정리 후
    op.execute("DROP TYPE IF EXISTS character_part_category;")
