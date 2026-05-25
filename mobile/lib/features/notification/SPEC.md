# F-029 / F-031 notification — 알림 (모바일)

## 개요

- **F-029**: 푸시 토큰을 백엔드에 등록하는 콜백 (`TokenRegistrar`) 구현 → `PushService.init`에 주입
- **F-031**: 알림 설정 화면 (`/settings/notifications`) — 3개 토글(new_message / idol_reply / marketing)

사용자: 팬, 아이돌. 마이페이지에서 진입.

---

## 의존 화면 / 데이터

- **화면 진입 경로**: 마이페이지 → "알림 설정" 항목 (마이페이지는 다른 슬라이스 — 본 슬라이스는 routes만 제공)
- **백엔드 API 호출**:
  - `POST /notification/device-tokens` (앱 시작 시, 토큰 갱신 시)
  - `DELETE /notification/device-tokens?token=xxx` (로그아웃 시 — 본 슬라이스 범위 X, 추후 auth에서 호출)
  - `GET /notification/prefs` (설정 화면 진입 시)
  - `PATCH /notification/prefs` (토글 변경 시)
- **읽기**: 없음 (Supabase 직결 X, 백엔드 경유)
- **쓰기**: 위 API
- **Realtime 구독**: 없음

---

## 의존 (core)

- `core.api.dio_client.dio` (백엔드 호출)
- `core.push.PushService.init` (TokenRegistrar 주입)
- `core.widgets.loading_view`, `error_view`

**main.dart 변경 (1줄)**: `PushService.init()` → `PushService.init(registrar: registerDeviceToken)`. main.dart는 features 간 통합 지점으로 본 슬라이스에서 등록. (이미 main.dart에 "features/notification에서 TokenRegistrar 주입 가능" 코멘트 명시됨)

---

## 비즈니스 룰

1. **토큰 등록**: PushService가 발급한 토큰을 `POST /notification/device-tokens`로 전송. 실패 시 silent log (앱 동작 차단 X).
2. **토큰 갱신**: PushService.onTokenRefresh 콜백도 같은 registrar 호출 (PushService가 이미 처리).
3. **설정 화면**: GET 후 토글 표시. 토글 변경 시 즉시 PATCH (debounce 없이). 실패 시 SnackBar + 이전 값으로 롤백.
4. **권한 거부 상태**: PushService가 permission denied면 init 단계에서 token 발급 X → registrar 호출 안 됨. 설정 화면은 정상 동작 (인앱 토글은 OS 권한과 별개).

---

## 엣지 케이스

- 첫 진입 시 prefs row 없음 → 백엔드가 default 생성 후 반환 → 토글 초기값 표시
- 토글 PATCH 진행 중 다른 토글 누름 → 각 토글 독립 상태로 처리 (각자 loading)
- 네트워크 에러 → SnackBar + 이전 값 복원

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// data/notification_repository.dart

/// FCM 토큰을 백엔드에 등록 (PushService TokenRegistrar로 전달).
Future<void> registerDeviceToken(String token, String platform);

/// 로그아웃 시 토큰 해제 (추후 auth 슬라이스에서 호출 예정).
Future<void> unregisterDeviceToken(String token);

// routes.dart
List<RouteBase> get notificationRoutes; // /settings/notifications
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. 앱 시작 → 로그인 → 백엔드 로그에 `POST /notification/device-tokens` 200 확인
2. `/settings/notifications` 진입 → 토글 3개 표시 (default: 메시지/답글 ON, 마케팅 OFF)
3. 마케팅 토글 ON → SnackBar 없음, 즉시 반영
4. 뒤로갔다 재진입 → 변경된 값 유지
5. (오프라인) 토글 변경 → 에러 SnackBar + 토글 원복

기대 결과: 토큰 등록 자동, 설정 화면 정상 동작, 푸시 실제 수신은 chat_message 완료 시 종단 검증.
