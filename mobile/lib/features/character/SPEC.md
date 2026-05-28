# F-039 / F-040 character — 캐릭터 방 + 정적 캐릭터 + 채팅 오버레이 (PR-1)

> 작업 단위 #13 character의 **PR-1만**.
> 후속: PR-2 (F-042+043 상태 DB), PR-3 (F-041 애니), PR-4 (F-044 선물 반응).
> v2 분리: F-045/046/047/048.

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

1. **F-039 방 배경**: 에셋 있으면 PNG 표시, 없으면 폴백:
   - 다크 퍼플 그라데이션 + 미세 grid 도트 (도트 픽셀 톤 흉내)
2. **F-040 정적 캐릭터**: 에셋 있으면 캐릭터 PNG center bottom, 없으면 폴백:
   - 라운드 실루엣 + "캐릭터 준비 중" 라벨
3. **채팅 카드**: 하단 ~55% 영역 반투명 (alpha 0.85) + blur. 카드 안에 message_list + input 그대로.
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

// routes.dart
List<RouteBase> get characterRoutes; // 빈 리스트 (오버레이 패턴, 라우트 없음)
```

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
