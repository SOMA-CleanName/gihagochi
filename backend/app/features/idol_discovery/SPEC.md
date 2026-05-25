# F-008 / F-009 / F-010 / F-011 아이돌 탐색 (idol_discovery)

> 작업 단위 #2. 모바일 화면 = 탐색 리스트 + 상세. mobile SPEC: [`../../../../mobile/lib/features/idol_discovery/SPEC.md`](../../../../mobile/lib/features/idol_discovery/SPEC.md)
> 진화하는 요구사항: [`feature-specs/idol_discovery.md`](../../../../feature-specs/idol_discovery.md)

---

## 개요

팬이 **승인된 활성 아이돌 목록을 탐색·검색**하고 **상세 화면에서 응원 시작 전 정보를 확인**할 수 있게 한다. 모바일이 dio로 본 API를 호출한다 (Supabase 직결 X).

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.2 (F-008 ~ F-011).

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| GET | `/idols` | 활성 아이돌 리스트 (검색/정렬/페이지) | AuthedUser |
| GET | `/idols/{idol_id}` | 아이돌 상세 (응원 팬 수 + 본인 응원 여부 포함) | AuthedUser |

### GET /idols

**쿼리 파라미터**
- `q`: 검색어 (선택, max 200자). `stage_name ILIKE '%q%'`
- `page`: 1부터 (선택, 기본 1)
- `page_size`: 1~50 (선택, 기본 20)

**응답** (200)
```jsonc
{
  "items": [
    {
      "id": "<uuid>",                 // idol_profiles.id = profiles.id
      "stage_name": "string",
      "bio_summary": "string|null",   // bio 앞 100자 잘림
      "thumbnail_url": "string|null",
      "activated_at": "2026-05-25T10:00:00Z"
    }
  ],
  "page": 1,
  "page_size": 20,
  "has_more": true
}
```

**처리 흐름**
1. base query: `idol_profiles INNER JOIN profiles ON idol_profiles.id = profiles.id` WHERE `profiles.role='idol' AND profiles.status='active' AND profiles.deleted_at IS NULL`
2. `q` 있으면: `AND idol_profiles.stage_name ILIKE '%q%'`
3. `ORDER BY idol_profiles.activated_at DESC`
4. `LIMIT page_size + 1 OFFSET (page-1)*page_size` (1개 더 가져와서 has_more 계산)
5. 응답으로 매핑 (bio_summary = bio 앞 100자)

### GET /idols/{idol_id}

**응답** (200)
```jsonc
{
  "id": "<uuid>",
  "stage_name": "string",
  "bio": "string|null",
  "thumbnail_url": "string|null",
  "activated_at": "2026-05-25T10:00:00Z",
  "fan_count": 42,                    // active subscriptions count
  "is_subscribed": true               // 현재 사용자의 응원 여부
}
```

**처리 흐름**
1. idol_profile + profile 조인해서 활성 조건 검증. 없거나 비활성이면 404.
2. `fan_count`: `SELECT COUNT(*) FROM subscriptions WHERE idol_id=? AND unsubscribed_at IS NULL`
3. `is_subscribed`: `SELECT 1 FROM subscriptions WHERE fan_id=auth.uid() AND idol_id=? AND unsubscribed_at IS NULL`
4. 본인이 그 아이돌 본인일 경우(`auth.uid() == idol_id`) `is_subscribed=false` (응원 불가)

---

## DB

- **읽기**: `idol_profiles`, `profiles`, `subscriptions` (count + 본인 여부)
- **쓰기**: 없음 (본 슬라이스는 SELECT only)
- **새 컬럼/테이블/RLS**: 없음. 기존 스키마 + `idx_idol_profiles_activated_at` 인덱스 활용.

### 슬라이스 contract

| 테이블 | 본 슬라이스 권한 | owner |
|---|---|---|
| `idol_profiles` | SELECT only | profile / admin |
| `profiles` | SELECT only (활성 조건 필터링) | auth / admin |
| `subscriptions` | SELECT only (count + 본인 여부) | subscription |

→ 본 슬라이스는 leaf SELECT 집합. mutation 없음.

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.AuthedUser` — 인증 의무
- `core.db.get_session` — AsyncSession 주입
- `core.errors.NotFoundError`
- `app.shared.models.IdolProfile`, `Profile`, `Subscription`
- `app.shared.enums.UserRole`, `UserStatus`
- **다른 피처 호출 없음**

---

## 비즈니스 룰

- **활성 아이돌 정의** = `idol_profiles` 존재 AND `profiles.role='idol'` AND `profiles.status='active'` AND `profiles.deleted_at IS NULL`. 모든 쿼리 베이스.
- 검색은 `stage_name ILIKE '%q%'` (case-insensitive, 부분 일치).
- 정렬은 `activated_at DESC` 고정 (1차).
- 페이지네이션은 offset/limit, `page_size`는 1~50으로 clamp, 기본 20.
- `q`가 빈 문자열 또는 None이면 전체 리스트.
- 상세 응답의 `fan_count`는 정확한 정수. 캐시 없음 (1차).
- 본인이 아이돌 본인 프로필 진입 시 `is_subscribed=false` (응원 불가, mobile에서 버튼 비활성).
- 페이지네이션 안정성은 보장 안 함 — 새 아이돌 활성화 시 같은 row가 다음 페이지에 중복될 수 있음 (1차 무시).

---

## 엣지 케이스

- **비활성 아이돌 직접 id 조회**: 404 (활성 조건 미통과)
- **정지된 아이돌**: 베이스 쿼리의 `status='active'` 조건이 자동 제외 → 리스트/검색/상세 모두 404
- **탈퇴한 아이돌**: 동일 (`deleted_at IS NOT NULL`)
- **검색어에 특수문자**: SQLAlchemy 파라미터 바인딩으로 안전. `%`, `_`는 LIKE wildcard인데 ILIKE 부분일치 의도와 부합 (사용자가 일부러 패턴 검색)
- **검색어 200자 초과**: Pydantic 422
- **page=0 / page<0**: Pydantic 422 (ge=1)
- **page_size>50 / <1**: Pydantic 422
- **존재하지 않는 idol_id**: 404
- **page 너무 큰 값**: 200 + 빈 items + has_more=false (성능 영향 작음)

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# 없음. idol_discovery는 leaf 슬라이스 — 다른 피처가 호출하지 않음.
# subscription 슬라이스도 idol_id를 알면 자체 처리 (구독 row INSERT).
```

---

## 수동 테스트 시나리오 (PR에 첨부)

### 시나리오 1: 활성 아이돌 리스트 골든 패스
1. 팬으로 로그인 → `GET /idols`
2. **기대**: 활성 아이돌 N명, `activated_at` 최신순 정렬, `has_more` 정확

### 시나리오 2: 검색
1. `GET /idols?q=아이돌` (또는 부분 문자열)
2. **기대**: `stage_name`이 해당 문자열 포함하는 아이돌만 반환 (case-insensitive)

### 시나리오 3: 페이지네이션
1. `GET /idols?page=1&page_size=2` → 첫 페이지
2. `GET /idols?page=2&page_size=2` → 다음 페이지 (중복 row 없음 — 단, 활성화 변동 없을 때)
3. 데이터보다 큰 페이지: `GET /idols?page=99` → 빈 items + has_more=false

### 시나리오 4: 정지된 아이돌 제외
1. admin으로 한 아이돌 정지 (`POST /admin/users/{id}/suspend`)
2. `GET /idols` → 그 아이돌 사라짐
3. `GET /idols/{그_id}` → 404

### 시나리오 5: 상세 — 응원 팬 수 + 본인 응원 여부
1. (사전) 한 아이돌에 N명 팬이 응원한 상태 (subscriptions row N개)
2. `GET /idols/{idol_id}` (본인은 응원 안 한 상태)
3. **기대**: `fan_count=N`, `is_subscribed=false`
4. subscriptions 테이블에 본인 row INSERT → 다시 조회 → `is_subscribed=true`

### 시나리오 6: 본인이 아이돌 본인 상세 진입
1. 아이돌 계정으로 로그인 → `GET /idols/{본인_id}`
2. **기대**: 정상 응답, `is_subscribed=false` (응원 불가)

### 시나리오 7: 검증
- `q` 200자 초과 → 422
- `page=0` → 422
- `page_size=100` → 422
- 존재하지 않는 idol_id → 404
