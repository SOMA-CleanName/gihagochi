# F-007(data) / F-014 / F-015 / F-016 채팅방 진입/리스트 (chat_room) — 모바일

> 작업 단위 #4. backend SPEC 없음 (모바일 단독, Supabase 직결 + RLS).
> 진화하는 요구사항: [`../../../../feature-specs/chat_room.md`](../../../../feature-specs/chat_room.md)
>
> 폴더명: `chat_room`. `core/router/app_router.dart`에 `...chatRoomRoutes` spread 1줄 + import 1줄 추가 필요 (구현 시).
> profile의 `chatListSlotProvider`를 ProviderScope.overrides로 override해서 메인 화면 통합.

---

## 개요

팬은 `/main`에서 응원 중인 아이돌의 채팅방 카드 리스트(thumbnail / 활동명 / 최근 메시지 미리보기 / 시간)를 본다. 카드 탭 → 채팅방(`/chat/:idolId`) 진입. 채팅방 본문(메시지/입력창)은 chat_message가 머지될 때 슬롯으로 채워짐. 롱프레스 = 메뉴 BottomSheet — 액션 리스트는 다른 피처(report/subscription/notification)가 슬롯으로 추가.

채팅방 식별자 = `idol_id` (1 idol = 1 채팅방). messages 테이블이 이미 idol_id 비정규화 보유 (RLS 단일 단계 평가용, 제품 헌법 §3).

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.3 (F-014/015/016/007).

---

## 화면 (Routes)

| Route | 화면 | 진입 조건 |
|---|---|---|
| `/main` (override) | profile의 `chatListSlotProvider`를 override해서 채팅방 카드 리스트 렌더 | role=fan (profile MainScreen 안에서) |
| `/chat/:idolId` | ChatRoomScreen — AppBar(thumbnail+활동명) + 메시지 슬롯 + 입력 슬롯 + 메뉴 BottomSheet | 활성 subscription (`unsubscribed_at IS NULL`) 있는 idolId만. 아니면 진입 차단 + idol_discovery로 |

> `/main` 자체는 profile이 등록. chat_room은 `chatListSlotProvider` Provider override로만 끼움 (의존 단방향).

---

## 의존 화면 / 데이터

- **화면 진입 경로**: profile의 `/main`에서 chat_room이 슬롯 override → 카드 탭 → `/chat/:idolId`
- **읽기 (Supabase 직결, RLS 보호)**:
  - `subscriptions` (자기 fan_id, `unsubscribed_at IS NULL`) — 활성 응원 목록
  - `idol_profiles` (구독 중인 idol_id들) — thumbnail_url (stage_name은 idol_discovery 컨텍스트에서만 사용)
  - `profiles` (해당 idol_id들) — display_name(= 채팅 표시명, 정책 2026-05-27), status (suspended면 차단)
  - `messages` (idol_id IN ..., 각 idol마다 최신 1개) — 미리보기 content + created_at
- **쓰기**: 없음 (본 PR scope)
- **Storage**: `idol-thumbnails` 버킷 — thumbnail_url path → signed URL 변환 (profile_repository와 동일 패턴)
- **백엔드 API**: 없음
- **Realtime 구독**: 본 PR 미사용. chat_message 머지 시 broadcast hook이 `chatListProvider.invalidateSelf()` 호출하도록 추후 추가

---

## 의존 (core)

- `core.auth.auth_service.supabaseProvider` — Supabase 직결 (RLS 의존)
- `core.router.app_router` — `...chatRoomRoutes` spread 1줄 추가
- `core.widgets.{avatar, loading_view, error_view, empty_view}` — 공용 위젯
- `intl` 패키지 (이미 pubspec.yaml에 있음) — 시간 포맷
- features/profile의 슬롯 Provider: `chatListSlotProvider`

> **메인 빌더 영역 변경 (본 PR 동봉)**: `mobile/lib/main.dart`의 `ProviderScope`에 `chatListSlotProvider.overrideWith((ref) => const FanChatList())` 1줄 + import 추가. `core/router`의 `...spread` 확장 메커니즘과 동일 논리 — Riverpod에서 한 피처가 다른 피처의 슬롯을 채우려면 ProviderScope.overrides가 유일한 깨끗한 경로. 사용자 사전 승인 받음.

> profile이 `chatListSlotProvider`를 export. chat_room이 자기 위젯으로 덮어쓰기.
> profile / chat_room 의존 단방향: chat_room → profile (chat_room이 profile의 slot 사용).

---

## 비즈니스 룰

- 채팅방 카드 = 활성 subscription 1건당 1장. 정렬: 최근 메시지 `created_at DESC` (메시지 없으면 `subscription.subscribed_at` 사용)
- 카드 표시 데이터:
  - thumbnail (없으면 display_name 이니셜 fallback — Avatar 위젯 패턴)
  - **닉네임** (`profiles.display_name`) — 채팅 컨텍스트는 display_name (정책 2026-05-27). 활동명(stage_name)은 idol_discovery 화면 전용.
  - 최근 메시지 미리보기 — RLS가 보여주는 메시지의 최신 1개의 `content`. text가 아니면 `[사진]` / `[음성]` placeholder. 1줄 truncate
  - 시간 — relative format: `방금 전` / `n분 전` / `n시간 전` / `n일 전` / 30일 이상은 `YYYY-MM-DD`
  - **안 읽은 카운트는 본 PR 제외** (chat_meta 영역)
- 빈 상태 (활성 subscription 0개) → chat_room 자체 빈 상태 위젯 ("응원 중인 아이돌이 없어요" + "아이돌 추가하기" CTA → `/discover`)
- 채팅방 진입 = 활성 subscription 검증 → 아니면 "응원하지 않는 아이돌입니다" + `/discover`로
- 아이돌 status='suspended' → 진입 차단 + "일시 정지된 아이돌" 메시지
- 채팅방 메뉴 (롱프레스 OR AppBar ⋮) = `chatRoomMenuActionsProvider` 리스트 BottomSheet. 본 PR default = `[]` + "메뉴 준비 중"
- 채팅방 본문 = `chatMessageListSlotProvider(idolId)` + `chatMessageInputSlotProvider(idolId)` 렌더. 본 PR default = placeholder
- pull-to-refresh로 카드 리스트 갱신 (RefreshIndicator)

---

## 엣지 케이스

- **활성 subscription 0개** → 자체 빈 상태 + `/discover` CTA. idol_discovery 미머지 시 토스트 fallback (profile 패턴 재사용)
- **subscription 이미 unsubscribed** + 카드 캐시 stale 상태로 진입 시도 → 진입 차단 + 자동 invalidate + 토스트
- **아이돌 status=suspended** → 진입 차단 + 카드에 회색 처리 + "일시 정지" 라벨
- **메시지 0개인 새 채팅방** → 카드 미리보기 자리에 "아직 메시지가 없어요" placeholder + subscription.subscribed_at 시간 표시
- **잘못된 `/chat/:idolId` UUID** → 진입 차단 + errorBuilder 또는 토스트
- **본인이 role=idol** (자기 채팅방 보기) → `/chat/<self_id>` 차단. 본인 아이돌 메인은 F-024 영역
- **thumbnail signed URL 발급 실패** → Avatar 위젯의 이니셜 fallback 자동 작동
- **카드 리스트 fetch 실패** (네트워크 등) → 슬롯 안에 ErrorView + 재시도
- **profile fetch 실패 (PGRST116)** → profile_repository가 자동 signOut 처리 (profile 기 검증된 흐름)

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// features/chat_room/application/slots.dart
//
// 채팅방 메시지 영역 슬롯 — chat_message가 머지 시 override.
// default = "메시지 기능 준비 중" placeholder.
final chatMessageListSlotProvider =
    Provider.family<Widget, String /*idolId*/>(
  (ref, idolId) => PlaceholderMessageList(idolId: idolId),
);

// 채팅방 입력창 슬롯 — chat_message가 머지 시 override.
final chatMessageInputSlotProvider =
    Provider.family<Widget, String /*idolId*/>(
  (ref, idolId) => PlaceholderMessageInput(idolId: idolId),
);

// 채팅방 메뉴 액션 리스트 — report / subscription / notification이 머지 시
// 자기 액션 추가. default = `[]`.
final chatRoomMenuActionsProvider = Provider<List<ChatRoomMenuAction>>((_) => []);

// 액션 DTO — 다른 피처가 자기 액션 표현.
class ChatRoomMenuAction {
  final IconData icon;
  final String label;
  final bool destructive; // 빨간색 처리용 (예: 응원 취소, 신고)
  final void Function(BuildContext context, String idolId) onTap;
  const ChatRoomMenuAction({
    required this.icon,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });
}

// features/chat_room/data/chat_room_repository.dart
//
// 채팅방 리스트 fetch (다른 피처가 직접 invalidate 필요할 때 — 예: chat_message 머지 후 broadcast hook).
// chatListProvider.invalidateSelf() 호출하면 자동 refetch됨. 직접 fetch 메서드 호출 X.
final chatListProvider = ... ; // AsyncNotifierProvider — 외부에서 invalidate만
```

> 위에 없는 함수/위젯은 internal.

---

## 수동 테스트 시나리오 (PR 첨부)

> **사전 조건**: dev DB에 mock subscription/idol 시드 실행 (`feature-specs/chat_room.md` 하단 SQL).

### 시나리오 1: 채널 리스트 표시
1. `/main` 진입 → 카드 2장 ("아이돌A", "아이돌B") 표시 확인
2. 각 카드: thumbnail (없으면 이니셜) + 활동명 + 최근 메시지 1줄 + 시간 (`방금 전` / 분/시간)
3. pull-to-refresh → 카드 리스트 재조회

### 시나리오 2: 빈 상태
1. 모든 subscription unsubscribed (`UPDATE subscriptions SET unsubscribed_at = NOW();`)
2. `/main` 새로고침 → "응원 중인 아이돌이 없어요" + CTA 표시
3. CTA 탭 → `/discover` (미머지 시 토스트)

### 시나리오 3: 채팅방 진입
1. 카드 탭 → `/chat/<idolA_id>` 진입
2. AppBar에 thumbnail + 활동명 표시
3. 메시지 영역 = "메시지 기능 준비 중" placeholder
4. 입력창 영역 = "입력 준비 중" placeholder
5. 우상단 ⋮ 또는 카드 롱프레스 → BottomSheet → "메뉴 준비 중" 안내

### 시나리오 4: 진입 차단
1. 활성 subscription 아닌 idol_id로 직접 `/chat/<random_idol_id>` 진입 시도
2. "응원하지 않는 아이돌입니다" 메시지 + 자동 뒤로가기 또는 `/main`으로 redirect

### 시나리오 5: 메시지 없는 채팅방
1. mock seed에서 메시지 INSERT 부분 제외하고 실행
2. 카드 미리보기 자리에 "아직 메시지가 없어요" + subscribed_at 시간 표시

### 시나리오 6: 슬롯 패턴 default 동작
1. chat_message / report / subscription / notification 미머지 상태
2. 채팅방 본문 = placeholder, 메뉴 = 빈 리스트 안내 — 모두 default 작동 확인
