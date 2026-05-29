# F-042 / F-043 character — 캐릭터 상태 + 행동 트리거

> 작업 단위 #13 character의 backend PR-2b. mobile PR-2c가 본 endpoint 호출.

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
