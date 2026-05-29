# F-039 / F-040 / F-042 / F-043 / F-044 character — 방 + 캐릭터 + 상태 + 행동 + 모먼트

> 작업 단위 #13 character.
> 현재 적용: PR-1 (F-039 방 배경, F-040 정적 캐릭터),
>           PR-4 (F-044 모먼트 카드 + 탭 반응),
>           PR-2 (F-042 상태 DB + F-043 행동 IF — backend 연동 완료, 탭 → POST /character/{idol}/actions).
> 후속: PR-3 (F-041 애니, Flutter implicit 기반).
> v2 분리: F-045/046/047/048.

## 백엔드 연동 (PR-2)

- `data/character_repository.dart`: `fetchState(idolId)`, `triggerAction(idolId, action)` — 백엔드 GET/POST 호출.
- `application/character_state_controller.dart`: `characterStateControllerProvider(idolId)` — Riverpod AsyncNotifier family.
  - `build`: `fetchState` (row 없으면 default idle 응답)
  - `trigger(action)`: `triggerAction` 호출 후 `state = AsyncData(next)` 즉시 갱신
- `presentation/widgets/character_placeholder.dart`: state.currentAction 기반 PNG 표시 + 탭 시 다음 순환 액션 백엔드 POST.

## 호흡 애니메이션 (PR-3, F-041)

Flutter implicit animation 만 사용 (Rive/flame 의존성 없음).

- **호흡 scale**: ±1.8% (`_breatheAmplitude`), `Curves.easeInOut`, 무한 왕복.
- **액션별 duration** — `_breatheDurationFor(action)`:
  - sleep: 4.2s (천천히)
  - eat: 3.4s
  - sing: 2.2s (빠르게)
  - 그 외: 2.8s
- **액션 전환 fade**: `AnimatedSwitcher` 280ms (`switchInCurve: easeOut`, `switchOutCurve: easeIn`).
- 탭 sparkle scale (±6%, 420ms one-shot)과 곱셈 합성 — 호흡 중에도 탭 부풀림 자연스럽게.

## 개요

채팅방 진입 시 풀스크린 "아이돌의 방" 배경 + 그 안에 정적 캐릭터 PNG가 서있고,
하단에 반투명 채팅 카드(메시지 list + 입력창)가 떠있는 다마고치형 레이아웃.

본 PR은 **정적**이라 DB·애니메이션·의존성 0. PR-2/3/4를 위한 슬롯 위치를 잡는다.

---

## 의존 화면 / 데이터

- **진입 경로**: chat_room의 `/chat/:idolId` → `chatRoomCharacterSlotProvider` override로
  본 슬라이스 `RoomCanvas` 렌더링.
- **읽기**: 없음 (정적). 추후 PR-2에서 `character_states` 읽기 추가 예정.
- **쓰기**: 없음.
- **에셋**: 1차는 폴백 (도트 그라데이션 방 + 캐릭터 자리 placeholder).
  실제 PNG는 디자이너 영역 (§8.1 후속).

---

## 의존 (core / 다른 피처)

- `core.theme.*` — 디자인 시스템 토큰
- `chat_room/application/slot_providers.dart` — `chatRoomCharacterSlotProvider`
  family Provider override 대상
- `chat_message/presentation/{message_list, message_input}.dart` —
  하단 채팅 카드 안에 다시 사용 (chat_room 슬롯 우회, 직접 import)

---

## 레이아웃 (F-040 명세 반영)

```
[Scaffold body]
 ┌─────────────────────────────────────────┐
 │   RoomCanvas (Stack, fill)              │
 │     - Layer 1: 방 배경 (그라데이션 + grid)│
 │     - Layer 2: 캐릭터 PNG (정적, center)│
 │     - Layer 3: 하단 반투명 채팅 카드     │
 │         ┌─────────────────────────────┐ │
 │         │ MessageList (스크롤)         │ │
 │         │ MessageInput                │ │
 │         └─────────────────────────────┘ │
 │           (높이 ~55%, glass effect)     │
 └─────────────────────────────────────────┘
```

이전 PR #96의 드래그 핸들 패턴은 **폐기** — F-040 명세는 오버레이 패턴.
chat_room_screen은 character 슬롯에 풀스크린 위임 + 자체 Column[char, list, input] 제거.

---

## 비즈니스 룰

1. **F-039 방 배경**: `assets/character/room_background.png` (862×1825, 9:19) BoxFit.cover + FilterQuality.none.
2. **F-040 정적 캐릭터**: `assets/character/character_*.png` 6종 (852×1846 공통, sad만 941×1672).
   - 표시 폭 = 화면 폭의 50% (`characterWidthRatio`), 높이 = `width × 1846/852` (`_characterCanvasAspect`).
   - sad는 BoxFit.contain으로 SizedBox 안에서 자동 비율 유지 — 약간 작게 보이는 게 정상.
   - `filterQuality: FilterQuality.none` (픽셀 아트 nearest neighbor).
   - 6종: idle / happy / sad / sing / eat / sleep — `CharacterActionType` enum과 매핑 (PR-2 백엔드 enum과 동일 이름).
   - 데모 토글: 캐릭터 탭 시 6종 순환 (PR-2에서 백엔드 상태 도입 시 제거 예정).
3. **채팅 카드**: 하단 ~55% 영역 반투명 (alpha 0.55) + blur 28. 카드 안에 message_list + input 그대로.
4. **본인 = idolId (아이돌 자기 채팅방)** : 동일 레이아웃. F-043 트리거 버튼은 PR-2에서.

---

## 엣지 케이스

- 키보드 열림 → 채팅 카드가 viewInsets.bottom만큼 위로. 캐릭터/방은 영향 X (Stack).
- 작은 디바이스 (높이 < 600) → 채팅 카드 height 비율 자동 ↑ (60~65%).
- 에셋 미수급 → 폴백 시각으로 동일 레이아웃 유지.

---

## 공개 인터페이스

```dart
// presentation/room_canvas.dart
class RoomCanvas extends ConsumerWidget {
  const RoomCanvas({super.key, required this.idolId});
  final String idolId;
}
// chat_room의 chatRoomCharacterSlotProvider가 본 위젯으로 override.
// chat_room_screen에선 body 전체를 char slot에 위임.

// integration/character_moment_trigger.dart — PR-4 공개 IF
/// 다른 피처(gift, chat_message 등)가 캐릭터 모먼트를 트리거할 때 호출.
/// 예: gift sheet close 후 chat_message에서 호출 → 캐릭터 위 카드 5s 표시.
void triggerCharacterMoment(WidgetRef ref, {
  required String idolId,
  required CharacterMomentKind kind, // gift | tap | feed | praise
  String? message,
});

// domain/character_moment.dart
enum CharacterMomentKind { gift, tap, feed, praise }

// routes.dart
List<RouteBase> get characterRoutes; // 빈 리스트 (오버레이 패턴, 라우트 없음)
```

---

## PR-4 추가 (F-044) — 캐릭터 모먼트 카드 + 탭 반응

### 범위

DB·의존성·마이그레이션 0. character 슬라이스 단독 변경.

1. **MomentCard** — 캐릭터 위쪽(채팅 카드 top 바로 위)에 떠있는 작은 glass 카드.
   - slide-in 200ms → 5s 표시 → fade-out 250ms → dispose
   - kind별 아이콘/색: gift=🎁 tertiary, tap=✨ secondary, feed=🍙 primary, praise=💜 primary
   - 메시지 옵션: "고마워!", "함께해서 행복해" 등 (kind별 기본값 + override 가능)

2. **캐릭터 탭 반응** — `CharacterPlaceholder` 탭 시:
   - 즉시 sparkle scale 애니메이션 (자기 위)
   - moment controller에 `CharacterMomentKind.tap` dispatch → MomentCard 표시
   - haptic feedback (HapticFeedback.lightImpact)

3. **공개 인터페이스** — `triggerCharacterMoment(...)` export.
   - gift 슬라이스 직접 호출 X (gift는 character 모름). chat_message 또는 후속 PR에서 호출.
   - 본 PR은 인터페이스만 export. 외부 호출자 변경 0.

### 비즈니스 룰

- 동일 idolId 재트리거 시 기존 moment 즉시 dispose + 새 moment 시작 (queue 안 함).
- moment 표시 중에도 채팅 입력/스크롤 정상 (pointer events 통과 영역).
- 캐릭터 탭 디바운스 500ms (sparkle 중 재탭 무시).

### 엣지 케이스

- 채팅창 풀로 올림(value=1) → MomentCard 가려질 수 있음. card는 채팅 카드 top 기준으로 위치하니 따라 올라감 (Stack 안 Positioned with chatTop offset).
- 위젯 dispose 중 timer fire → safe (mounted 체크).
- 같은 kind 연속 → 카드 reset 후 재시작 (시각적으로 깜빡임 OK).

### 수동 테스트 시나리오

1. 채팅방 진입 → 캐릭터 탭 → sparkle + MomentCard ("반가워" tap kind) 5s 표시
2. 5s 내 다시 탭 → 카드 즉시 reset + 재시작
3. 채팅창 위로 드래그 → 카드도 따라 위로
4. 카드 표시 중 메시지 입력 → 정상 동작 (카드 위 텍스트 펜딩 X)
5. 디바이스 회전 (있다면) → 카드 위치 자연스럽게 재계산

### 메인 빌더 영역 변경 (PR-4)

- 없음. character 슬라이스 단독.

---

## 수동 테스트 시나리오 (PR 첨부)

1. 팬으로 채팅방 진입 → 풀스크린 방 배경 + 캐릭터 placeholder + 하단 반투명 채팅 카드
2. 메시지 입력/전송 동작 정상 (chat_message 슬롯 그대로)
3. 키보드 열기 → 채팅 카드만 위로, 캐릭터/방은 유지
4. 아이돌 본인 채팅방 진입 → 동일 레이아웃 (트리거 UI는 PR-2)
5. 캐릭터/방 에셋 0인 상태에서 폴백 시각 정상

기대 결과: 정적 레이아웃 완성, chat_message/input 종단 동작.

---

## 메인 빌더 영역 변경 (본 PR 동봉)

- `mobile/lib/main.dart`: `chatRoomCharacterSlotProvider.overrideWith((ref, idolId) => RoomCanvas(idolId: idolId))` 1줄 추가
- `mobile/lib/features/chat_room/presentation/chat_room_screen.dart`: 본문 Column[char, list, input] → 슬롯에 풀스크린 위임 (RoomCanvas가 채팅 카드 자체 포함)

> chat_room owner = 본인이므로 직접 수정 OK (다른 owner 영역 아님).
