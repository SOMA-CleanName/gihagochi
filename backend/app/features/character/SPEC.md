# F-042 / F-043 character — 캐릭터 상태 + 행동 트리거

> 작업 단위 #13 character의 backend.
> - PR-2b (머지 완료): F-042 상태 DB + F-043 행동 트리거 IF
> - ~~PR-5: F-050/F-051/F-052 Avatar Forge 스키마~~ → **2026-06-08 폐기** (flame 채택, `0006_avatar_forge_drop`). 아래 Avatar Forge 섹션은 이력 보존용
> - 새 방향: flame 기반 렌더링 (별도 작업 단위 SPEC 예정)

## 개요

아이돌별 캐릭터 상태(`current_action` + hunger/happiness/energy)를 조회하고,
누구나 행동을 트리거하면 state.current_action 업데이트 + action_log INSERT.

MVP는 권한 단순화 — AuthedUser면 모두 트리거 가능. 비즈니스 룰(팬 vs 아이돌 차이)은 후속 PR.

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| GET  | `/character/{idol_id}/state` | 캐릭터 현재 상태. row 없으면 default(idle, 100/100/100) | 비인증 OK |
| POST | `/character/{idol_id}/actions` | 행동 트리거 → log INSERT + state 업데이트 | AuthedUser |

### POST 요청 본문

```jsonc
{ "action": "happy" }
```

`action` ∈ `idle | happy | sad | sing | eat | sleep` (`character_action_type` ENUM).

### POST 응답

```jsonc
{
  "log": { "id": "...", "idol_id": "...", "action": "happy", "performed_by": "...", "performed_at": "..." },
  "state": { "idol_id": "...", "current_action": "happy", "hunger": 100, "happiness": 100, "energy": 100, "updated_at": "..." }
}
```

---

## DB

- **읽기**: `profiles`, `character_states`
- **쓰기**: `character_states` (INSERT/UPDATE), `character_action_logs` (INSERT)
- **새 컬럼/테이블 필요**: 없음 — `0004_character_states`로 이미 생성됨 (PR-2a)

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.AuthedUser` — POST 인증
- `core.db.get_session`
- (다른 피처 호출 안 함)

---

## 비즈니스 룰

- GET은 비인증 OK — 활성 아이돌의 캐릭터 상태는 공개.
- state row 없으면 GET은 default 응답 (DB INSERT 없음). 첫 POST 시 row 새로 생성.
- POST는 AuthedUser면 모두 트리거 가능 (MVP). performed_by = 호출자 user_id.
- `performed_by=None`은 시스템 트리거 (시간 경과 cron 등) — backend 내부 호출 전용. router는 항상 AuthedUser라 None 안 들어옴.
- 마이그레이션 시점 RLS:
  - `character_states`: 공개 read + 본인(idol_id == auth.uid()) INSERT/UPDATE만 RLS 허용
  - `character_action_logs`: 공개 read + 본인 INSERT만 RLS 허용
  - 따라서 팬 트리거(idol_id ≠ user_id) INSERT는 backend가 service role로 처리해야 RLS 우회 (현재 service는 그렇게 동작).

---

## 엣지 케이스

- 존재하지 않는 `idol_id` → 404 NotFoundError.
- idol_id가 idol 역할 아닌 일반 user여도 router는 그대로 동작 (profile 존재만 검증). 역할 검증은 후속.
- 동시 호출 race (state UPDATE 동시) → SQLAlchemy session 단위로 단순 last-write-wins. 별도 락 없음.

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# service.py
async def get_state(session: AsyncSession, idol_id: UUID) -> CharacterStateResponse: ...

async def record_action(
    session: AsyncSession,
    idol_id: UUID,
    action: CharacterActionType,
    performed_by: UUID | None,
) -> ActionResponse: ...
```

`performed_by=None`은 시스템 트리거 전용 (cron 등). 외부 피처는 항상 user_id 전달.

---

## 수동 테스트 시나리오 (PR에 첨부)

1. 비인증으로 `GET /character/{anyIdolId}/state` → 200 default 응답
2. 존재하지 않는 idol_id → 404
3. 인증 토큰으로 `POST /character/{idolId}/actions` body=`{"action":"happy"}` → 201 + state.current_action="happy"
4. 같은 idol_id로 다른 action 다시 POST → state 업데이트, log 2번째 row 추가
5. 비인증 POST → 401

기대 결과: state 정상 업데이트, log append-only.

---

# Avatar Forge (PR-5 스키마 — F-050 / F-051 / F-052)

> 작업 단위 #13 character의 backend PR-5 (`0005_avatar_forge_schema`).
> CRUD API와 카탈로그 시드는 PR-6에서. 본 PR은 **스키마만**.

## 개요

아이돌이 마네킹 베이스에서 부위별 부품(머리/눈/입/옷/신발/액세서리)을 조립해 자기 캐릭터를 디자인 (Avatar Forge). MVP는 메이커 + 정적 카탈로그까지. 팬 선물 → 갈아끼우기는 v2.1.

본 PR은 3개 테이블 + 1개 ENUM + 2개 트리거 + RLS 정책만. 행 INSERT(시드)는 PR-6.

---

## DB

### 신규 ENUM

**`character_part_category`**: `head` | `eyes` | `mouth` | `top` | `bottom` | `shoes` | `accessory`

`character_parts.category` 컬럼과 `validate_slot_state_keys()` 트리거 양쪽이 동일 ENUM 참조 — 두 곳 리터럴 박힘 회피.

### 신규 테이블 3개

**`character_parts`** — 글로벌 부품 카탈로그 (운영/admin이 관리)
```
id          uuid PK, default gen_random_uuid()
category    character_part_category NOT NULL
asset_path  text NOT NULL
z_index     int NOT NULL          -- bottom(10) < top(20) < shoes(30) < head(40) < eyes(50) < mouth(60) < accessory(70)
anchor_x    int NOT NULL          -- 853×1844 캔버스 기준 좌표
anchor_y    int NOT NULL
rarity      text NOT NULL DEFAULT 'common' CHECK IN ('common','rare','epic')
tags        text[] DEFAULT '{}'
created_at  timestamptz NOT NULL DEFAULT NOW()
```
인덱스: `character_parts(category)` — 메이커 카테고리별 부품 그리드 조회

**`idol_character_slot_state`** — 아이돌별 현재 슬롯 상태
```
idol_id     uuid PK REFERENCES profiles(id) ON DELETE CASCADE
slots       jsonb NOT NULL DEFAULT '{}'
              예: {"head": "<uuid>", "eyes": "<uuid>", "top": "<uuid>", ...}
              키는 character_part_category ENUM 값만 (TRIGGER 검증)
updated_at  timestamptz NOT NULL DEFAULT NOW()  (트리거로 자동 갱신)
```
인덱스: `slots` GIN — v2.1+ JSONB 쿼리 대비

**`idol_part_inventory`** — 아이돌별 보유 부품
```
idol_id           uuid REFERENCES profiles(id) ON DELETE CASCADE
part_id           uuid REFERENCES character_parts(id) ON DELETE RESTRICT
source            text NOT NULL DEFAULT 'default' CHECK IN ('default','gift')
acquired_at       timestamptz NOT NULL DEFAULT NOW()
gift_from_fan_id  uuid NULL REFERENCES profiles(id) ON DELETE SET NULL
PRIMARY KEY (idol_id, part_id)

CHECK inventory_source_gift_consistency:
  (source='default' AND gift_from_fan_id IS NULL)
  OR (source='gift' AND gift_from_fan_id IS NOT NULL)
```

ON DELETE 정책 의도:
- `character_parts ON DELETE RESTRICT` — 운영이 카탈로그에서 부품 삭제 시도 자체 차단. dangling slots 방지
- `gift_from_fan_id ON DELETE SET NULL` — 팬 탈퇴 시 인벤토리 자체는 보존, 출처만 익명화
- `idol_id ON DELETE CASCADE` — 아이돌 탈퇴 시 인벤토리/슬롯 같이 정리

`idol_part_inventory(idol_id)` 단독 인덱스 **생성 안 함** — PK가 복합 `(idol_id, part_id)`라 idol_id-only 쿼리에 PK 인덱스 leftmost prefix가 자동 사용됨. redundant 인덱스는 write 비용만 추가.

### 신규 트리거 2개

**`validate_slot_state_keys`** (BEFORE INSERT/UPDATE on `idol_character_slot_state`)
- `slots` JSONB 키가 모두 `character_part_category` ENUM 값에 포함되는지 검증
- 위반 시 `RAISE EXCEPTION 'invalid slot key: %, allowed: %'`
- **왜 CHECK 아닌 TRIGGER**: PostgreSQL은 CHECK constraint 안에 subquery / set-returning function 금지. `jsonb_object_keys`는 set-returning이라 CHECK 안에서 못 씀. TRIGGER가 유일 선택지
- **ENUM 추가 시 함수 변경 불필요**: 함수가 `enum_range(NULL::character_part_category)` 사용해 ENUM 값 동적 참조

**`trg_slot_state_updated_at`** (BEFORE UPDATE on `idol_character_slot_state`)
- 0001_initial의 `set_updated_at()` 함수 재사용 (character_states와 동일 패턴)

---

## RLS 정책 + SELECT 의도

| 테이블 | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `character_parts` | **모든 사용자** | service role/admin | service role/admin | service role/admin |
| `idol_character_slot_state` | **모든 사용자** (공개 정체성) | 본인 (`auth.uid()=idol_id`) | 본인 | service role/admin |
| `idol_part_inventory` | **본인만** (사적) | service role | service role | service role/admin |

**왜 `slot_state`는 공개인데 `inventory`는 사적?**
- `slot_state` = "지금 이 아이돌이 어떻게 생겼는지" = 다마고치 본질 = 아이돌의 공개 정체성. F-008 탐색 화면 미리보기 + 채팅방 진입 둘 다 필요. 응원 관계 체크는 F-016(채팅방 진입)에서 이미 막아둠.
- `inventory` = "어떤 부품을 가졌는지" = 사적 영역. 다른 아이돌/팬에게 노출 불필요. 본인 메이커에서만 사용.

INSERT/UPDATE 정책 미생성 = service role/admin만 가능 (RLS는 기본 deny). MVP는 default 지급을 backend가 service role로 INSERT. v2.1 gift도 동일 — 팬이 직접 INSERT 하는 게 아니라 gift 슬라이스가 service role로 UPSERT.

---

## 카테고리 추가 시 체크리스트

새 카테고리(예: `hat`, `wings`) 추가 시 다음 모두 갱신:

1. **DB**: `ALTER TYPE character_part_category ADD VALUE 'hat';`
   - ⚠️ **PG 제약**: ENUM ADD VALUE 후 그 값 사용은 **다른 마이그 또는 커밋 후 단계**에서. 같은 트랜잭션 내 사용 불가. 한 마이그에 ADD VALUE + 시드 같이 박으면 실패.
2. `validate_slot_state_keys()` 함수: **변경 불필요** (enum_range로 동적 참조)
3. **Backend** Pydantic enum (`shared/enums.py` 또는 character schemas): 새 값 추가
4. **Mobile** `CharacterPartCategory` enum: 새 값 추가
5. **z-order 표준** 문서 갱신: 어디 끼울지 결정
6. 첫 시드 row: PR-6 시드 스크립트 또는 admin 콘솔에서 INSERT

---

## application 영역 (PR-5 범위 밖, PR-6/9 책임)

본 마이그(PR-5)는 스키마/제약/RLS만 강제. 다음 검증은 application 레벨:

1. **`gift_from_fan_id` role 검증** — `profiles(id)` FK만으론 role='fan' 검증 안 됨. PR-6 service layer에서 검증.
2. **중복 보유 시 source 업그레이드 UPSERT** — PK 충돌 시 application이 `INSERT ... ON CONFLICT (idol_id, part_id) DO UPDATE SET source='gift', gift_from_fan_id=...` 처리. default → gift 일방향 업그레이드.
3. **`slots` JSONB 내부 part_id 무결성** — JSONB는 FK 불가. PR-6 service layer에서 slot_state 저장 시 모든 part_id 값이 `character_parts.id`에 존재하는지 확인.
4. **저장 경합 (낙관적 락)** — slot_state.updated_at 이미 확보됨. PR-6/8에서 WHERE updated_at = $expected 패턴 적용 결정.

---

## DB (PR-5)

- **읽기**: (본 PR 신규 endpoint 없음)
- **쓰기**: (본 PR 신규 endpoint 없음 — 스키마만)
- **새 컬럼/테이블**: `character_parts`, `idol_character_slot_state`, `idol_part_inventory` 신규 + `character_part_category` ENUM + 2 트리거

## API (PR-6에서 채울 예정)

placeholder — 다음 표는 PR-6 작성 시 확정.

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| GET    | `/character/parts`                       | 부품 카탈로그 (category 필터) | AuthedUser |
| GET    | `/character/{idol_id}/slot-state`        | 아이돌 현재 슬롯              | 비인증 OK  |
| PUT    | `/character/{idol_id}/slot-state`        | 본인 슬롯 저장                | AuthedUser (본인) |
| GET    | `/character/{idol_id}/inventory`         | 본인 인벤토리                 | AuthedUser (본인) |

## 공개 인터페이스 (PR-6에서 채울 예정)

placeholder.

```python
# service.py (예정)
async def list_parts(session, category: CharacterPartCategory | None) -> list[CharacterPart]: ...
async def get_slot_state(session, idol_id: UUID) -> SlotState | None: ...
async def save_slot_state(session, idol_id: UUID, slots: dict[str, UUID]) -> SlotState: ...
async def list_inventory(session, idol_id: UUID) -> list[InventoryEntry]: ...
async def grant_default_parts(session, idol_id: UUID) -> int: ...  # 가입 직후 default 지급
```

## 비즈니스 룰 (PR-5 범위)

- 스키마/제약/RLS만 본 PR 책임
- 행 INSERT 없음 (시드 = PR-6)
- 기존 `character_states` / `character_action_logs` / `fan_character_bonds` 수정 없음

## 수동 테스트 시나리오 (PR-5)

alembic upgrade head 후 (DB 접근 가능한 환경에서):

1. 3개 테이블 + 1 ENUM + 1 함수 + 2 트리거 존재 확인
2. `INSERT INTO idol_character_slot_state (idol_id, slots) VALUES ('<uuid>', '{"hat":"x"}'::jsonb)` → TRIGGER EXCEPTION 차단
3. `INSERT INTO idol_character_slot_state (idol_id, slots) VALUES ('<uuid>', '{"head":"x"}'::jsonb)` → OK
4. slot_state UPDATE → updated_at 자동 갱신 확인
5. inventory `source='gift', gift_from_fan_id=NULL` insert 시도 → CHECK 차단
6. inventory `source='default', gift_from_fan_id=<uuid>` insert 시도 → CHECK 차단
7. profile 삭제 → inventory/slot_state CASCADE 확인
8. character_parts 삭제 시도 (inventory 참조 있을 때) → RESTRICT 실패 (정상)
9. `alembic downgrade -1` → 깔끔 롤백 (set_updated_at은 살아있어야 함). 다시 `upgrade head` → 멱등성 확인
