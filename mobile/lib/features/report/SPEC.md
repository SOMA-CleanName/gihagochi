# F-033 report — 신고 모달 (모바일)

## 개요

팬이 부적절한 메시지를 신고하는 BottomSheet. chat_message 등 메시지 표시 슬라이스가 메시지 롱프레스/메뉴에서 `showReportSheet(context, messageId)` 호출.

사용자: 팬. 우선순위 P1.

---

## 의존 화면 / 데이터

- **화면 진입 경로**: chat_message가 메시지 롱프레스 메뉴에서 호출 (chat_message PR에서 wire — chat_room의 `chatRoomMenuActions` 슬롯이 아니라 메시지 단위 액션이라 chat_message 책임)
- **백엔드 API**: `POST /reports` (camelDio 사용)
- **읽기**: 없음
- **Realtime 구독**: 없음

---

## 의존 (core)

- `core.api.dio_client.camelDio` ← **신규 슬라이스 권장. PR #44**
- `core.widgets.*` (Material 위젯만 사용 — loading state는 자체 처리)

---

## 비즈니스 룰

1. **신고 사유 10~500자** — UI에서 카운트 표시, 백엔드도 동일 validator
2. **중복 신고 시 SnackBar 안내** — 409 ConflictError를 catch해서 "이미 신고했습니다"
3. **자기 메시지 신고 차단** — 백엔드가 400 ValidationError. UI는 메시지 표시 (호출 측이 자기 메시지엔 메뉴 안 띄우는 게 정석)
4. **모달 닫기는 성공 후 자동** — 실패 시 모달 유지 + SnackBar

---

## 엣지 케이스

- 네트워크 오류 → SnackBar "신고 전송 실패: ..." + 모달 유지
- 백엔드 404 (메시지 없음) → SnackBar + 모달 닫기
- 입력 중 키보드 닫기 / 회전 등은 flutter 기본 동작

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// presentation/report_sheet.dart

/// 메시지 신고 BottomSheet 표시. chat_message가 메시지 롱프레스에서 호출.
Future<void> showReportSheet(BuildContext context, {required String messageId});

// data/report_repository.dart  ← 직접 호출 X (sheet 안에서 사용). public 노출은 sheet만.

// routes.dart
List<RouteBase> get reportRoutes; // 빈 리스트 (모달만, 라우트 없음)
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. (chat_message wiring 후) 메시지 롱프레스 → "신고" → BottomSheet 표시
2. reason textarea 10자 미만 → 신고 버튼 비활성
3. 10~500자 입력 → 버튼 활성 → 탭 → 200 → 모달 닫힘 + SnackBar "신고 접수됨"
4. 같은 메시지 다시 신고 → 409 → SnackBar "이미 신고한 메시지입니다"
5. 자기 메시지 신고 (수동 테스트 어려움 — 백엔드 단위 테스트로 위임)

기대 결과: 신고 전송 + 멱등 보호 + UI 피드백.
