# F-012 / F-013 응원 (subscription) — 모바일

> 작업 단위 #3. backend SPEC: [`../../../../backend/app/features/subscription/SPEC.md`](../../../../backend/app/features/subscription/SPEC.md)
> 진화하는 요구사항: [`../../../../feature-specs/subscription.md`](../../../../feature-specs/subscription.md)
>
> 본 슬라이스는 **독립 화면 없음**. controller + repository만 제공. 다른 슬라이스(idol_discovery / chat_room / profile)에서 import해서 사용.

---

## 개요

응원 시작/취소 액션의 Repository + Controller. UI 화면은 본 슬라이스에 없음 — idol_discovery 상세 등 다른 슬라이스의 화면에서 본 controller를 호출. routes.dart는 빈 리스트 export (라우터 등록은 noop).

---

## 화면 (Routes)

| Route | 화면 | 진입 조건 |
|---|---|---|
| (없음) | — | 다른 슬라이스 화면 내에서 액션 호출 |

`routes.dart`는 `final List<RouteBase> subscriptionRoutes = [];` 빈 리스트로 두되 app_router.dart에 등록은 함 (일관성).

---

## 의존 화면 / 데이터

- **읽기/쓰기**: 백엔드 API
  - `POST /idols/{idol_id}/subscribe` — 응원 시작
  - `DELETE /idols/{idol_id}/subscribe` — 응원 취소
- **Supabase 직결**: 없음
- **Realtime 구독**: 없음

---

## 의존 (core)

- `core.api.dio_client.dio`
- `core.error.error_handler`

> 본 슬라이스는 다른 features 슬라이스 import 안 함. 단, **호출하는 쪽 슬라이스** (idol_discovery 등)가 본 슬라이스의 `SubscriptionController` 또는 `SubscriptionRepository`를 import.

---

## 비즈니스 룰

- 응원 시작/취소 후 호출 측 controller(예: `idolDetailControllerProvider(id)`)를 invalidate해서 fresh 조회 유도. 1차는 단순 invalidate (optimistic update X).
- 백엔드가 응답한 `is_active` 값을 클라이언트가 신뢰. 별도 추측 X.
- 에러 처리: 백엔드 400/404를 한국어 메시지로 SnackBar 표시 + ErrorHandler 위임.

---

## 엣지 케이스

- 같은 idol에 빠른 더블탭 → controller가 진행 중이면 noop (또는 마지막 호출만 처리)
- 네트워크 끊김 → ErrorView/SnackBar 표시
- 백엔드 멱등 응답(200) → 추가 처리 없이 호출 측 invalidate

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// Repository — dio 호출.
class SubscriptionRepository {
  Future<SubscriptionDetail> subscribe(String idolId);
  Future<SubscriptionDetail> unsubscribe(String idolId);
}

// Provider for repository.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(...);

// Controller — 외부에서 family 형태로 호출.
@riverpod
class SubscriptionController extends _$SubscriptionController {
  // 액션 메서드 호출 시 자동으로 isLoading / error 표시.
  Future<void> subscribe(String idolId);
  Future<void> unsubscribe(String idolId);
}
```

> 호출 측은 액션 후 본인 controller invalidate (예: `ref.invalidate(idolDetailControllerProvider(idolId))`).

---

## 수동 테스트 시나리오 (PR 첨부)

> 본 슬라이스는 UI 없어서 시나리오는 호출 측 슬라이스에서 검증.
> 본 PR에서는 백엔드 API 동작 확인까지 (backend SPEC 시나리오 1~8). UI 통합 시나리오는 idol_discovery placeholder 교체 PR에서 다룸.

### (참고) 통합 시나리오 — 후속 PR에서 검증
1. idol_discovery 상세 → "응원하기" 탭 → 본 controller.subscribe 호출 → 상세 자동 refresh → 버튼 "응원 중"으로 바뀜
2. 다시 "응원 중" 탭 → unsubscribe → 버튼 "응원하기"로 복귀
