# F-027 gift — 선물하기 UI (준비 중)

## 개요

팬이 채팅방 또는 직접 경로로 선물하기를 진입하면 "준비 중" 안내 표시. 1차 출시 범위는 **UI only** (결제/실 로직은 제품 헌법 #4에 따라 범위 외).

사용자: 팬. 우선순위 P1.

---

## 의존 화면 / 데이터

- **화면 진입 경로**:
  1. (주) chat_room이 채팅방 안에서 `showGiftComingSoonSheet(context, idolId: ...)` 호출 — BottomSheet
  2. (보조) `/gift?idolId=...` 직접 경로 — FullScreen 백업 (마이페이지 등에서 진입)
- **읽기**: 없음 (UI only)
- **쓰기**: 없음 (백엔드 호출 X)
- **Realtime 구독**: 없음

---

## 의존 (core)

- `core.widgets.*` (필요 시 — 현재는 Material 위젯만 사용)
- (백엔드 호출 없음 → `dio` 미사용)

---

## 비즈니스 룰

1. **UI only** — 결제, 선물 로직 X. 본 화면은 안내 + 닫기만.
2. **idolId optional** — chat_room 외 경로에서도 진입 가능. 향후 실로직 시 대상 식별 위해 받아 둠 (현재는 미사용).
3. **닫기 액션** — Sheet는 `Navigator.pop`, FullScreen은 `context.pop()` (go_router).

---

## 엣지 케이스

- BottomSheet 표시 중 앱 백그라운드 복귀 → flutter 기본 동작으로 유지
- 직접 경로 접근 시 idolId 없으면 `null`로 처리 (방어적, 안내 메시지는 동일)

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// presentation/gift_coming_soon_sheet.dart

/// 채팅방 등에서 호출. modal bottom sheet로 "준비 중" 안내 표시.
/// chat_room이 SPEC.md에 본 함수 명시 후 호출.
Future<void> showGiftComingSoonSheet(BuildContext context, {String? idolId});

// routes.dart
List<RouteBase> get giftRoutes; // /gift?idolId=...
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. 앱에서 `/gift` 직접 접근 → "준비 중" 안내 + 닫기 버튼
2. 닫기 탭 → 이전 화면 복귀
3. `/gift?idolId=abc` 접근 → 동일 화면 (idolId는 내부 보존, 미사용 표시)
4. chat_room에서 추후 호출 시 BottomSheet 형태 (chat_room PR에서 연결)

기대 결과: 안내 표시 + 닫기 정상 동작, 백엔드 호출 0건.
