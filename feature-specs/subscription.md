# F-012 / F-013 응원 (subscription) — 요구사항 노트

> 작업 단위 #3 (응원 구독). 폴더: `features/subscription`.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 →
> `backend/app/features/subscription/SPEC.md` + `mobile/lib/features/subscription/SPEC.md` 로 옮긴다.

---

## 한 줄 목표

팬이 활성 아이돌을 **응원 시작 (구독)** 하고 **응원 취소 (구독 해지)** 할 수 있게 하며, 다른 슬라이스(idol_discovery/chat_room/profile)가 응원 상태를 호출·표시할 수 있게 한다.

---

## 요구사항

### F-012 응원 시작
- [ ] 팬이 활성 아이돌에 응원 시작 → `subscriptions` row INSERT (또는 재구독 시 같은 row의 `unsubscribed_at=NULL` UPDATE)
- [ ] 같은 fan_id가 이미 active 응원 중이면 멱등 (200, 현재 row 반환)
- [ ] 자기 자신 아이돌에는 응원 불가 (DB CHECK `subs_no_self` + 백엔드 명시 검증)
- [ ] 비활성 아이돌(suspended/deleted/role 다름)에 응원 시도 → 404
- [ ] 1차는 **무료** — 결제 플로우 없음 (P2의 "결제 도입" 항목 보류)

### F-013 응원 취소
- [ ] 활성 응원 중인 row를 `unsubscribed_at=NOW()` UPDATE
- [ ] 이미 unsubscribed면 멱등 (200, 현재 row 반환)
- [ ] **취소 시 과거 메시지 보존 정책** — SCHEMA.md §6.3 "재구독 시 자동 복원" 결정 그대로
- [ ] 취소 후 채팅방 메인에서 사라짐 (chat_room 슬라이스의 SELECT 조건이 처리)

---

## 결정 사항 (Decisions)

- `2026-05-25`: **F-012 1차에 포함** (무료 응원). P2의 "결제 도입 시 결제 플로우" 항목은 보류 → 추후 결제 슬라이스 합류 시 본 슬라이스의 POST 전에 끼워넣음.
- `2026-05-25`: **백엔드 API 경유** (idol_discovery, admin 패턴과 일관). subscriptions 테이블 owner인 본 슬라이스가 INSERT/UPDATE 처리. 모바일은 dio.
- `2026-05-25`: **활성 아이돌 검증** = idol_discovery의 공식과 동일 (`idol_profiles` 존재 + `role=idol` + `status=active` + `!deleted`). 응원 대상 비활성이면 404.
- `2026-05-25`: **재구독 = 같은 row의 UPDATE** (SCHEMA.md §6.3). PK가 (fan_id, idol_id) 복합이라 자연스러운 UPSERT 패턴. `subscribed_at`은 첫 구독 시점 유지, `last_read_at`은 NOW() 갱신.
- `2026-05-25`: **멱등성 정책** — active 응원 중 재요청 시 200(현재 row), 이미 unsubscribed 사용자가 취소 재요청 시 200(현재 row). 명시 에러 안 던짐.
- `2026-05-25`: **자기 자신 응원 차단은 백엔드에서 명시 400** + DB CHECK가 fallback.
- `2026-05-25`: **공개 인터페이스 = `is_subscribed(session, fan_id, idol_id)`** — 다른 슬라이스가 응원 여부 표시용으로 호출 가능. 현재 idol_discovery는 자체 SELECT로 처리 중이라 즉시 사용은 안 되지만 향후 chat_room/profile에서 사용.
- `2026-05-25`: **API endpoint 형식 = REST 자원형** — `POST /idols/{idol_id}/subscribe` (응원 시작), `DELETE /idols/{idol_id}/subscribe` (응원 취소). 명시형(`/subscriptions/start`)보다 RESTful.
- `2026-05-25`: **idol_discovery 상세의 "응원하기" placeholder 교체는 본 PR 외**. 그 코드 수정은 다른 슬라이스 직접 수정 = 절대 룰 4 위반. 본 슬라이스 머지 후 별도 `fix/idol-discovery-subscribe-action` PR로 분리.
- `2026-05-25`: **모바일은 controller + repository만 제공**. 독립 화면 없음 (`routes.dart`는 빈 리스트). 다른 슬라이스가 import해서 호출.
- `2026-05-25`: **응원 시작/취소 후 UI 반영 방식** — `is_subscribed` 응답을 받아 호출 측 controller가 invalidate. 1차는 단순 invalidate (정확성 우선, optimistic update는 향후).

---

## 의문 / 미정 (Open Questions)

1. **idol_discovery 상세 placeholder 교체 PR 시점** — 본 슬라이스 머지 직후 또는 다음 작업 단위와 묶음. 작음.
2. **응원 한도** — 한 팬이 응원 가능한 아이돌 수 제한? 1차는 무제한.
3. **응원 시작 시 환영 메시지** — 자동으로 채팅방에 시스템 메시지 INSERT? notification 슬라이스 합류 시 검토.

---

## 엣지 케이스 / 메모

- 비활성 아이돌에 응원 시도 → 404 "아이돌을 찾을 수 없습니다"
- 자기 자신 응원 시도 → 400 "본인을 응원할 수 없습니다"
- 이미 active 응원 중 → 200 (현재 row 반환, 멱등)
- 이미 unsubscribed → 200 (현재 row 반환, 멱등)
- 한 번도 응원 안 한 사용자가 취소 시도 → 404 "응원 기록을 찾을 수 없습니다"
- 재구독 시 `subscribed_at` 유지 + `unsubscribed_at=NULL` + `last_read_at=NOW()` 갱신
- DB CHECK `subs_no_self` 위반 → IntegrityError → 백엔드가 400으로 변환
- 동시에 두 디바이스에서 응원/취소 → 마지막 호출 승. PK race는 upsert로 안전

---

## SPEC.md 로 승격된 항목

- [x] API 엔드포인트 (POST/DELETE /idols/{idol_id}/subscribe)
- [x] 읽기/쓰기 테이블 (subscriptions, idol_profiles, profiles)
- [x] 공개 인터페이스 (`is_subscribed`)
- [x] 비즈니스 룰 (활성 검증, 재구독 같은 row, 멱등성, 자기 응원 차단)
- [x] 엣지 케이스

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#3 응원), §10.1
- 피처 상세: `docs/FEATURES.md` §3.2 (F-012, F-013)
- DB 스키마: `docs/SCHEMA.md` §4.4 (subscriptions), §6.3 (재구독 결정)
- 선행 슬라이스: idol_discovery (활성 아이돌 정의 동일하게 사용)
- 후속 슬라이스: chat_room (응원한 아이돌의 채팅방 진입), notification (응원 시작 시 환영 메시지?)
- 이슈: #22
