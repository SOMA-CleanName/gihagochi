# F-039 ~ F-044 character (flame 기반) — 방 + 캐릭터 + 상호작용

> 작업 단위 #13 character. **flame 게임엔진 기반** (2026-06-04 v2 결정).
> 진리원: [`feature-specs/character.md`](../../../../feature-specs/character.md) v2 — 의사결정/매트릭스/PR 분할.
> 본 SPEC.md = mobile 슬라이스 **확정 계약**.

## 현재 적용

- **PR-B/C/D/E/F/G1/I-part1/H**: flame Game + RoomWorld + CharacterComponent + 호흡 + 랜덤 액션 + 탭 + 드래그 + 풀스크린 전환 + 가구 placeholder

## 폴더 구조

```
mobile/lib/features/character/
├── domain/
│   ├── character_action.dart        # CharacterActionType enum (idle/happy/sad/sing/eat/sleep)
│   ├── character_state.dart         # CharacterState (current_action + hunger/happiness/energy)
│   └── character_moment.dart        # CharacterMoment + CharacterMomentKind (gift/tap/feed/praise)
├── data/
│   └── character_repository.dart    # fetchState(idolId) / triggerAction(idolId, action)
├── application/
│   ├── character_state_controller.dart   # Riverpod AsyncNotifier.family
│   └── character_moment_controller.dart  # 5s timer
├── presentation/
│   ├── room_canvas.dart             # chat_room slot — Stack[GameWidget, ChatCard, MomentCard]
│   └── widgets/moment_card.dart     # F-044 카드 (gift/tap/feed/praise UI)
├── game/                            # ★ flame 영역
│   ├── encore_character_game.dart   # EncoreCharacterGame extends FlameGame
│   ├── room_world.dart              # RoomWorld extends World
│   ├── character_component.dart     # CharacterComponent extends SpriteComponent
│   └── furniture_component.dart     # FurnitureComponent extends RectangleComponent (placeholder)
└── integration/
    └── action_debug_menu.dart       # chatRoomMenuActionsProvider 슬롯 (디버그)
```

## 디스플레이 정책

| 항목 | 값 |
|---|---|
| flame logical canvas | **480×800** (3:5, 도트 게임 저해상도) |
| filterQuality | `FilterQuality.none` (도트 보존) |
| Camera | `CameraComponent.withFixedResolution(480, 800)` |
| 게임 배경색 | `#1A0F2E` (방 PNG 로딩 전 + letterbox 대비) |
| 캐릭터 width | 300 logical px (viewport의 62.5%) |
| 캐릭터 anchor | `Anchor.bottomCenter` |
| 캐릭터 발 위치 | viewport `(0, 350)` |
| 호흡 amplitude | 2 logical px (Y sine wave) |
| 가구 임계 거리 | 100 logical px |

## flame 영역 공개 인터페이스

```dart
// game/encore_character_game.dart
class EncoreCharacterGame extends FlameGame {
  EncoreCharacterGame({VoidCallback? onCharacterTap});
  final VoidCallback? onCharacterTap;  // 탭 → 외부에서 모먼트 + 백엔드 처리
}

// game/room_world.dart — game.world로 접근
class RoomWorld extends World with HasGameReference<EncoreCharacterGame> {
  late final CharacterComponent character;  // setAction(...) 호출 진입점
}

// game/character_component.dart
class CharacterComponent extends SpriteComponent with TapCallbacks, DragCallbacks {
  CharacterComponent({required double targetWidth, VoidCallback? onTap, ...});
  CharacterActionType get currentAction;
  void setAction(CharacterActionType next);  // sprite + size 동기 교체
}
```

## 백엔드 연동 (F-042 / F-043)

- `data/character_repository.dart`: `fetchState(idolId)` / `triggerAction(idolId, action)` — 백엔드 GET/POST.
- `application/character_state_controller.dart`: Riverpod AsyncNotifier.family.
  - `build`: `fetchState` (row 없으면 default idle 응답)
  - `trigger(action)`: POST → 응답 즉시 `state = AsyncData(next)`.

### state ↔ flame 동기

`presentation/room_canvas.dart`에서 `ref.listen`:
- `characterStateControllerProvider(idolId)` 변화 → `world.character.setAction(state.currentAction)`
- 트리거 경로 통합: **탭** / **디버그 메뉴** / **cron** / **AI(v2)** 모두 같은 path.

## 호흡 + 랜덤 액션 (F-041, flame)

- **호흡**: `update(dt)` 안에서 `position.y = baseY + sin(elapsed * 2π / period) * 2`.
- **액션별 주기** (`_breatheMs`):
  - sleep 4.2s / eat 3.4s / sing 2.2s / 그 외 2.8s
- **랜덤 액션 스케줄러**: 5~12s 사이 랜덤 간격.
  - idle 50% + 나머지 5종 동등 분포 (각 10%).
- **드래그 중 호흡 + 랜덤 액션 일시정지** (`_isDragging`).

## 인터랙션

### 탭 (PR-F)
- `CharacterComponent.onTapDown` → `onTap?.call()` → `EncoreCharacterGame.onCharacterTap` → `RoomCanvas._handleCharacterTap`:
  1. `HapticFeedback.lightImpact()`
  2. `characterMomentControllerProvider(idolId).show(CharacterMomentKind.tap)`
  3. `characterStateControllerProvider(idolId).trigger(CharacterActionType.happy)` (백엔드)
- 백엔드 응답 → `ref.listen` → `character.setAction(happy)`.

### 드래그 (PR-G1)
- `DragCallbacks.onDragUpdate` → `position += event.localDelta`.
- 드래그 종료 → `_baseY = position.y` (새 위치에서 호흡 재개).
- 백엔드 위치 저장(PR-G2)은 마이그레이션 영역 별도 PR (미진행).

### 가구 근접 (PR-H placeholder)
- `RoomWorld.update`에서 매 frame `character.position ↔ 각 가구 position` 거리 측정.
- 임계 100 logical px 안 → 가장 가까운 가구의 `actionWhenNear` 트리거.
- **백엔드 우회**: 환경 트리거라 백엔드 저장 안 함.
- 매핑: bed → sleep / desk → eat / chair → sing.

## F-044 모먼트 카드 (Flutter)

- `presentation/room_canvas.dart` Layer 3에 `MomentCard` (Positioned, chatTop 위).
- 5s 타이머 + 4 kind (gift / tap / feed / praise) UI.
- 트리거: 탭 callback / 외부 (gift 슬라이스 등) 향후 확장.

## 의존 (다른 슬라이스)

- `core/theme/*` — 디자인 시스템.
- `chat_room/application/slot_providers.dart` — `chatRoomCharacterSlotProvider` override 대상.
- `chat_message/presentation/{message_list, message_input}.dart` — RoomCanvas Layer 2 ChatCard 안.
- `chat_room/application/chatRoomMenuActionsProvider` — 디버그 액션 메뉴 슬롯.

## 자산

- `mobile/assets/character/`:
  - `room_background.png` (853×1844) — 방 배경
  - `character_{idle,happy,sad,sing,eat,sleep}.png` — 액션 6종
    - sad만 941×1672 (다른 비율) — `CharacterComponent._aspect`에서 액션별 height 자동 계산
  - 부품 PNG는 Avatar Forge v1 폐기로 제거됨 (PR-I-part1 이전 정리).

## 정책 결정 사항 (자체 결정, 검증 후 조정 가능)

| 항목 | 값 | 비고 |
|---|---|---|
| 호흡 amplitude | 2px | anchor=bottomCenter라 발 흔들림 — 미세하게 |
| 랜덤 액션 idle 가중치 | 50% | 안정성/변화 균형 |
| 랜덤 액션 간격 | 5~12s | 너무 자주/드물지 않게 |
| 탭 액션 | happy | 긍정 반응 |
| 가구 임계 거리 | 100px | viewport 480의 17% |
| 가구 → 액션 매핑 | bed:sleep / desk:eat / chair:sing | 자체 결정 |

## 후속 PR (계획)

- **PR-G2** (메인 빌더 영역): 백엔드 위치 저장 — `character_states` ADD COLUMN position_x/y
- **v2 PR-V2-A~F**: 시간대별/문맥별 자율 행동, LLM 트리거, Scenario 메이커, 가구 본격, 누적 성장 등
- **v3**: Rive 정밀 모션, AI 행동 트리, LLM 인터프리터

## Open Questions

- flame_riverpod 도입 시점 — callback 패턴 한계 도달 시
- 가구 PNG 정합성 — 방 배경 PNG와 anchor 좌표 매칭 (Scenario PoC 결과 의존)
- 캐릭터 발 위치 (y=350) 검증 — 방 바닥 라인과 맞는지
- GameWidget 영역 letterbox — viewport 3:5 vs 화면 비율 차이
- 가구 setAction 직접 호출 vs 백엔드 trigger — 환경 트리거 정책 v2에서 결정
