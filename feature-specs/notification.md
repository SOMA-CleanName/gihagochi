# F-029 / F-031 notification — 요구사항 노트

> 진화하는 요구사항 공간. 확정 시 → `backend/app/features/notification/SPEC.md` + `mobile/lib/features/notification/SPEC.md`

---

## 한 줄 목표

팬/아이돌이 자기 디바이스에서 푸시 알림을 받을 수 있게 토큰을 등록하고(F-029), 알림 종류별로 인앱 토글할 수 있다(F-031).

---

## 요구사항

- [x] 디바이스 토큰 등록 API (멱등)
- [x] 디바이스 토큰 해제 API
- [x] 알림 설정 조회 API (lazy create)
- [x] 알림 설정 수정 API (부분 업데이트)
- [x] 모바일: PushService.TokenRegistrar 구현
- [x] 모바일: 알림 설정 화면 (`/settings/notifications`)
- [ ] **푸시 발송 자체는 본 슬라이스 범위 X** — chat_message 등 발송 측 슬라이스가 `get_active_tokens_for_user` + `is_notification_enabled` 호출

---

## 결정 사항 (Decisions)

- `2026-05-25`: **토큰 멱등 + reassign** — 같은 token이 다른 user_id로 오면 user_id 갱신. 이유: 같은 디바이스 계정 전환 시 잘못 발송 방지.
- `2026-05-25`: **DELETE는 쿼리 파라미터** — FCM 토큰에 `/`, `:` 포함 가능 → path 인코딩 회피.
- `2026-05-25`: **prefs lazy create** — GET 시 row 없으면 default 생성 후 반환. 사용자별 prefs row 보장 시점이 첫 조회 시점.
- `2026-05-25`: **NotificationKind는 features/notification/schemas.py Literal** — shared/enums 추가 시 메인 빌더 영역 변경 + 마이그레이션 필요해 회피.
- `2026-05-25`: **푸시 발송 로직 본 슬라이스 제외** — chat_message가 본 슬라이스 공개 인터페이스 호출 (`get_active_tokens_for_user`, `is_notification_enabled`). 종단 검증은 chat_message 완료 후.
- `2026-05-25`: **PushInitializer 위젯 패턴 채택 (main.dart 갱신)** — 초안은 "main.dart에서 PushService.init(registrar: ...) 직접 호출"이었으나 main.dart의 PushService.init은 ProviderScope 생성 전 호출되어 `ref.read(notificationRepositoryProvider)` 접근 불가. 해결: `features/notification/presentation/push_initializer.dart` ConsumerStatefulWidget 도입 → `ProviderScope > PushInitializer > _GihagochiApp` 구조로 main.dart의 PushService.init 호출 제거 + PushInitializer wrap. main.dart는 이미 다른 슬라이스도 features import 패턴 사용 중 (chat_room slot, profile slot).
- `2026-05-25`: **app_router.dart에 notificationRoutes 1줄 추가** — _template SPEC에 명시된 수동 패턴, 다른 슬라이스도 동일 진행.
- `2026-05-25`: **로그아웃 시 토큰 해제는 추후 auth가 호출** — 본 슬라이스는 `unregisterDeviceToken` 공개 인터페이스만 노출.

---

## 의문 / 미정 (Open Questions)

(없음 — 모두 결정)

---

## 엣지 케이스 / 메모

- 시뮬레이터에서 APNS 미지원 → `PushService.init`이 try/catch graceful degrade (이미 main.dart에서 처리). 토큰 발급 안 되면 registrar 호출 안 됨 → 백엔드 로그에 `POST /device-tokens` 없을 수 있음 (정상).
- google-services.json (Android) / GoogleService-Info.plist (iOS) 필요 — 사용자가 이미 iOS는 배치. Android는 본 슬라이스 종단 검증 시점에 별도 확인.
- 토큰 reassign 케이스 테스트는 통합 테스트로 검증 (CI에선 같은 user 멱등만 검증).
- 실제 푸시 발송 검증은 chat_message 완료 후 (FCM Console로 수동 전송 또는 채팅 종단 시나리오).

---

## SPEC.md 로 승격된 항목

- [x] API 엔드포인트 명세 (4개)
- [x] 읽기/쓰기 테이블 (device_tokens, notification_prefs)
- [x] 공개 인터페이스 (get_active_tokens_for_user, is_notification_enabled / registerDeviceToken, unregisterDeviceToken, notificationRoutes)
- [x] 비즈니스 룰 (멱등, reassign, lazy create, 부분 업데이트, 본인 데이터만)

---

## 참고

- 백엔드 SPEC: `backend/app/features/notification/SPEC.md`
- 모바일 SPEC: `mobile/lib/features/notification/SPEC.md`
- 전체 피처 명세: [`docs/FEATURES.md`](../docs/FEATURES.md) §3.5
- DB 스키마: [`docs/SCHEMA.md`](../docs/SCHEMA.md) §4.8, §4.9
- 이슈: #27
- mobile/lib/core/push/push_service.dart (TokenRegistrar 인터페이스)
