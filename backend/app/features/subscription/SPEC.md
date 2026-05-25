# F-012 / F-013 응원 (subscription)

> 작업 단위 #3. mobile SPEC: [`../../../../mobile/lib/features/subscription/SPEC.md`](../../../../mobile/lib/features/subscription/SPEC.md)
> 진화하는 요구사항: [`feature-specs/subscription.md`](../../../../feature-specs/subscription.md)

---

## 개요

팬이 활성 아이돌에 **응원 시작 / 응원 취소**. subscriptions 테이블 owner. 재구독은 같은 row의 UPDATE (SCHEMA.md §6.3). 다른 슬라이스(idol_discovery / chat_room / profile)가 본인 응원 여부 확인용 public 함수 호출 가능.

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.2 (F-012, F-013).

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| POST | `/idols/{idol_id}/subscribe` | 응원 시작 (또는 재구독 = unsubscribed_at=NULL 갱신) | AuthedUser |
| DELETE | `/idols/{idol_id}/subscribe` | 응원 취소 (unsubscribed_at=NOW()) | AuthedUser |

### POST /idols/{idol_id}/subscribe

요청 본문: 없음
응답: `200` + `SubscriptionDetail`

처리 흐름:
1. `idol_id == auth.uid()` → 400 "본인을 응원할 수 없습니다."
2. 활성 아이돌 검증 (idol_profiles 존재 + role=idol + status=active + !deleted) → 404
3. 기존 (fan_id=auth.uid(), idol_id=idol_id) row 조회.
   - 없으면 INSERT (`subscribed_at=NOW()`, `unsubscribed_at=NULL`)
   - active(unsubscribed_at IS NULL) → 200 (현재 row, 멱등)
   - inactive(unsubscribed_at 있음) → UPDATE (`unsubscribed_at=NULL`, `last_read_at=NOW()`, `subscribed_at`은 유지)
4. flush + refresh → 응답

### DELETE /idols/{idol_id}/subscribe

요청 본문: 없음
응답: `200` + `SubscriptionDetail`

처리 흐름:
1. 기존 row 조회 — 없으면 404 "응원 기록을 찾을 수 없습니다."
2. 이미 unsubscribed → 200 (현재 row, 멱등)
3. active → UPDATE (`unsubscribed_at=NOW()`)
4. flush + refresh → 응답

> 아이돌 활성 여부는 취소 시점에 검증 X (정지된 아이돌도 취소는 허용)

---

## DB

- **읽기**: `idol_profiles`, `profiles` (활성 검증), `subscriptions`
- **쓰기**: `subscriptions` (INSERT / UPDATE only — DELETE 안 함, soft-cancel)
- **새 컬럼/테이블/RLS**: 없음. PK `(fan_id, idol_id)` + CHECK `subs_no_self` + 인덱스 `idx_subscriptions_active_by_fan/idol` 그대로.

### 슬라이스 contract

| 테이블 | 본 슬라이스 권한 | owner |
|---|---|---|
| `subscriptions` | INSERT / UPDATE (cancel) | subscription (본 슬라이스) |
| `idol_profiles` | SELECT only (활성 검증) | profile / admin |
| `profiles` | SELECT only | auth / admin |

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.AuthedUser`
- `core.db.get_session`
- `core.errors.NotFoundError`, `ValidationError`
- `app.shared.models.Profile`, `IdolProfile`, `Subscription`
- `app.shared.enums.UserRole`, `UserStatus`
- **다른 피처 호출 없음**

---

## 비즈니스 룰

- 응원 시작 시 활성 아이돌만 가능. 비활성 → 404
- 자기 자신 응원 시도 → 400 (백엔드 명시) + DB CHECK fallback
- 같은 (fan_id, idol_id) row는 UPSERT 패턴: 재구독 = 같은 row UPDATE
- 멱등성: active 재요청 / 이미 unsubscribed 재요청 모두 200 (현재 row)
- 한 번도 응원 안 한 사용자의 취소 시도 → 404
- 동시 호출 race는 DB PK + atomic UPDATE로 안전 (마지막 호출 승)

---

## 엣지 케이스

- 비활성 아이돌 응원 시도: 404
- 자기 응원 시도: 400
- 멱등 케이스 (active 중복 시작 / unsubscribed 중복 취소): 200
- 없는 row 취소: 404
- 정지된 아이돌의 응원 취소: 허용 (활성 검증 안 함)
- DB CHECK 위반: IntegrityError → 백엔드 400 변환

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
async def is_subscribed(
    session: AsyncSession, fan_id: UUID, idol_id: UUID
) -> bool:
    """fan이 idol을 active로 응원 중인지. idol_discovery / chat_room / profile 표시용."""

async def get_subscription(
    session: AsyncSession, fan_id: UUID, idol_id: UUID
) -> SubscriptionDetail | None:
    """단건 조회 — 활성/비활성 무관. row 자체 없으면 None.
    notification 슬라이스 / chat_room이 last_read_at 등 보조 정보 필요할 때.
    """
```

> 위에 명시 안 된 함수는 internal.

---

## 수동 테스트 시나리오 (PR에 첨부)

### 시나리오 1: 응원 시작 골든 패스
1. (사전) 활성 아이돌 1명 dev DB에 존재
2. 팬으로 로그인 → `POST /idols/{idol_id}/subscribe` → 200
3. **기대**: subscriptions에 row INSERT (`subscribed_at`/`last_read_at`=NOW, `unsubscribed_at`=NULL)

### 시나리오 2: 멱등 (active 중복 시작)
1. 시나리오 1 이어서 같은 호출 한 번 더
2. **기대**: 200, 같은 row 반환, INSERT/UPDATE 없음

### 시나리오 3: 응원 취소
1. 시나리오 1 이후 `DELETE /idols/{idol_id}/subscribe` → 200
2. **기대**: `unsubscribed_at=NOW()` UPDATE

### 시나리오 4: 재구독 (같은 row UPDATE)
1. 시나리오 3 이후 다시 `POST /idols/{idol_id}/subscribe`
2. **기대**: `unsubscribed_at=NULL` 복원, `subscribed_at`은 시나리오 1 시점 그대로, `last_read_at`은 NOW() 갱신
3. SQL: `SELECT subscribed_at, unsubscribed_at, last_read_at FROM subscriptions WHERE fan_id=? AND idol_id=?` 확인

### 시나리오 5: 자기 응원 차단
1. 아이돌 본인이 자기 자신 응원 시도
2. **기대**: 400 "본인을 응원할 수 없습니다."

### 시나리오 6: 비활성 아이돌 응원 차단
1. admin으로 한 아이돌 정지
2. 팬이 그 아이돌 응원 시도
3. **기대**: 404

### 시나리오 7: 없는 응원 취소
1. 한 번도 응원 안 한 idol_id로 DELETE
2. **기대**: 404 "응원 기록을 찾을 수 없습니다."

### 시나리오 8: 정지된 아이돌 응원 취소는 허용
1. 응원 중인 아이돌이 admin에 의해 정지됨
2. 팬이 DELETE 호출
3. **기대**: 200 (활성 검증 안 함)
