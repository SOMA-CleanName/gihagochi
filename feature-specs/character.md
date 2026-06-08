# F-039 ~ F-054 캐릭터 (flame 기반) — 요구사항 노트

> 작업 단위 #13 (캐릭터/육성). 폴더: `features/character` (+ flame Game 영역 추가)
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 → `mobile/lib/features/character/SPEC.md` (+ `backend/app/features/character/SPEC.md`) 로 옮긴다.
>
> **2026-06-04 v1**: Avatar Forge(부품 조립) 신규 작성
> **2026-06-04 v2 (현재)**: flame 게임엔진 채택, 전체 재설계
>
> ⚠️ v1의 Avatar Forge 부품 시스템(슬롯 + 부품 카탈로그)은 **폐기**. PR #128 (Avatar Forge v1 스키마) → 머지됨 (2026-06-04). 사용 안 함. 별도 PR로 삭제 마이그 예정 (PR #130에서 시도됐으나 close — 별도 트랙). 본 v2 문서가 character 슬라이스 진리원.

---

## 한 줄 목표

채팅 위에 살아있는 게임 캐릭터를 얹어, **"내가 키운 캐릭터가 살아있는 것처럼 반응하는 경험"**을 차별점으로 제공한다. 단순 채팅 아바타가 아닌 **인터랙티브 다마고치 게임**.

---

## 비전 — 우리 서비스의 본질

**경쟁력 = 캐릭터.** 유사 서비스(지하돌 채팅앱)와의 차별점이 캐릭터로 좁혀짐. 이 비전이 성립해야 서비스 의미가 있다.

비전의 8개 요소:

1. **본인이 좋아하는 사람을 본 딴 캐릭터** — 정체성 (아이돌별 고유)
2. **그 사람의 말에 맞춰 반응/동작/행동** — LLM ↔ 캐릭터 브릿지
3. **클릭/탭 시 모션 변화** — 인터랙션
4. **잡아서 끌고 → 위치 이동** — 드래그 핸들링
5. **위치 기반 가구 상호작용** — 게임 객체 시스템
6. **평소에 알아서 움직임** — 자율 행동 / AI
7. **외형 커스터마이징** — 메이커 + 갈아끼우기
8. **팬 선물 → 캐릭터 변화** — 정서적 연결

위 8개를 **MVP / v2 / v3 단계로 분리**해서 실현. 단번에 다 못 함 — 점진 도입.

---

## 결정 history (최신순)

### 2026-06-04 — **flame 게임엔진 채택, Avatar Forge v1 폐기**

**채택 결정**:
- 비전(인터랙션·자율 행동·가구 상호작용) = 본질적으로 2D 게임
- Flutter Stack + Rive로는 한계 명확 (탭은 가능하나 드래그·가구·자율 행동 어려움)
- flame = Flutter용 2D 게임엔진. 기존 Flutter 코드 그대로 살림, 캐릭터/방 영역만 GameWidget 임베드
- Unity/Godot은 오버스펙. 우리 케이스엔 flame이 정답

**Avatar Forge v1 부품 시스템 폐기 이유**:
- 부품 조립 시스템 = 양산성에 매몰되어 본질 우회한 결과
- 첫 시드 5명은 어차피 외주/직접 제작이 답
- 양산은 Scenario.gg(LoRA 기반) 같은 SaaS가 더 우수
- PR #128(`character_parts` + `idol_part_inventory` + `idol_character_slot_state`) 머지됨 (2026-06-04), 사용 안 함. 삭제 마이그는 별도 트랙 (PR #130 close, 우선순위 낮음)

**매몰비용 인지**:
- PR-1~4 머지된 일부 재작성 (LayeredAvatar 폐기, flame Game으로)
- 방 배경/모먼트 카드 일부 로직은 살림
- 부품 자가 조달 중단

### 2026-06-04 — **8 영역 × 3 단계 비전 매트릭스**

| 영역 | MVP | v2 | v3 |
|---|---|---|---|
| **1. Rendering Engine** | flame 기본 셋업 + GameWidget | Camera/Layer 분리 | 멀티 씬, 트랜지션 |
| **2. Character Component** | Sprite + 액션 PNG 6종 | 프레임 애니메이션 (idle 4프레임) | Rive 본격 통합 |
| **3. Asset Pipeline** | 현재 GPT 똥쟁이 + Scenario PoC | Scenario LoRA 채택 (또는 외주) | 외주 + LoRA 혼합 |
| **4. Interaction System** | 탭 + 드래그 | 핀치 줌 | 멀티터치, 복합 제스처 |
| **5. Room + Furniture** | 가구 Component 3~5개 + 위치 기반 상호작용 | 가구 N개 확장, 배치 가능 | 팬 선물 가구, 방 꾸미기 본격 |
| **6. Autonomous Behavior** | 호흡 + N초마다 랜덤 액션 | 시간대별 자율 행동 | AI 행동 트리 (Behavior Tree) |
| **7. LLM ↔ Character Bridge** | 없음 | 키워드 매칭 트리거 | LLM 인터프리터 |
| **8. Avatar Maker** | 없음 (똥쟁이 1체 고정) | Scenario 기반 메이커 | 가구 + 옷 갈아끼우기 |

**MVP 핵심 = 영역 1, 2, 4, 5의 절반, 6의 절반.** 나머지는 v2~v3 단계 도입.

### 2026-06-04 — MVP 범위 세부 결정

- **logical 캔버스 = 480×800** (도트 게임 표준 저해상도. PNG는 853×1844지만 flame 내부 좌표는 480×800 사용. 화면 비율에 맞춰 scale up)
- **MVP 인터랙션 = 탭 + 드래그** (가구는 위치 기반 상호작용까지)
- **MVP 가구 = 3~5개** (예: 침대, 책상, 의자). 캐릭터가 가구 근처 위치 → 가구별 상호작용 트리거
- **MVP 자율 행동 = 호흡 + N초마다 랜덤 액션** (눈 깜빡임, 살짝 움직임 등 — 정확 정책은 PR-E 시점 결정)
- **메이커는 v2** — MVP 동안 똥쟁이 1체 고정 + 영입 데모. 첫 시드 5명은 외주 또는 정훈 직접 제작 가능성
- **F-027 선물 UI** — MVP 동안 "준비중" 유지, v2.1에서 본격

### 2026-06-04 — Scenario PoC 별도 트랙

- flame 채택과 **독립** (flame = 렌더링/로직, Scenario = 에셋 공급)
- 정훈 직접 진행 (1주 PoC, $15~25)
- 평가 항목: 도트 톤 품질 / 캐릭터 정체성 유지 / 변형 다양성 / 학습 시간 / API 통합 / 비용
- PoC 통과 → v2 메이커 시스템에 Scenario 채택
- PoC 실패 → 외주 트랙 (1체 30~80만원)

### 2026-06-04 — Motion Distill 폐기 (이전 결정)

PoC에서 일러스트 → 픽셀화 결과가 서비스 톤 불일치 확인. 기술은 작동하나 미적 결과가 "도트 게임 캐릭터"가 아닌 "축소된 일러스트". 폐기.

### 2026-06-04 — Avatar Forge v1 채택 (이후 폐기, history 보존)

Slot Forge 진화형으로 일시 채택했으나, 비전 재검토(2026-06-04 오후)에서 본질 한계 확인 → flame 채택으로 폐기.

### 2026-05-29 — Q1 캐릭터 상태 귀속 모델

**스키마는 C(하이브리드), 구현은 A(아이돌 귀속)부터** — 유효함, 유지.
- DB: `character_states`(공유) + `fan_character_bonds`(팬별, v2)
- MVP: `character_states`만 작동
- `fan_character_bonds`는 v2 (F-045)

### 2026-05-29 — UI 레이아웃

- 검정 배경 자르기 X, 방 풀스크린
- 채팅창 반투명 + 위아래 드래그 가능
- 드래그 범위: 최저 ~55-60%, 최고 ~15-20%
- 본 결정은 flame 채택 후에도 유지 (Flutter Stack의 채팅창 부분은 그대로)

---

## 요구사항

### MVP (작업 단위 #13 본체, flame 기반)

#### 머지 완료 (PR-1~4) — flame 마이그 시 일부 재작성

- [x] F-039 캐릭터 방 배경 렌더링 — flame World 배경으로 이관 필요
- [x] F-040 정적 캐릭터 + 채팅 오버레이 — CharacterComponent로 재작성
- [x] F-041 캐릭터 상태/표정 애니메이션 — flame SpriteComponent + state swap
- [x] F-042 캐릭터 상태 DB + 시간 경과 변화 — 백엔드 그대로 유지
- [x] F-043 행동 트리거 인터페이스 (수동) — 그대로 유지
- [x] F-044 팬 행동→캐릭터 반응 (선물 카드/모먼트) — Flutter UI 부분 유지, 모션 트리거는 flame으로

#### flame 마이그 신규

- [ ] F-049 flame Game 셋업 (`EncoreCharacterGame extends FlameGame`)
- [ ] F-050 CharacterComponent — Sprite + 호흡 + 액션별 swap
- [ ] F-051 InteractionSystem — 탭 + 드래그
- [ ] F-052 RoomWorld + FurnitureComponent — 3~5개 가구 + 위치 기반 상호작용
- [ ] F-053 AutonomousBehavior — 랜덤 액션 스케줄러
- [ ] F-054 기존 PR-1~4 코드 정리 (LayeredAvatar / Stack 합성 제거)

### v2 (영입 시작 후 단계적)

- [ ] F-045 캐릭터 성장 / 누적 상태 — `fan_character_bonds` 활용
- [ ] F-046 시간대별 방 변화 (조명)
- [ ] F-047 AI 문맥 분석 → 행동 자동 트리거 (LLM 통합)
- [ ] F-055 (v2) 시간대별 자율 행동 (밤=sleep, 점심=eat)
- [ ] F-056 (v2) 키워드 기반 LLM 트리거
- [ ] F-057 (v2) Scenario 기반 메이커 (PoC 통과 시)
- [ ] F-058 (v2) 가구 ↔ 캐릭터 본격 상호작용
- [ ] F-053 선물 → 부품/가구 발송 (v2.1)
- [ ] F-054 갈아끼우기 즉시 적용 (v2.1)

### v3 (본격 차별점)

- [ ] F-059 Rive 본격 통합 (정밀 모션)
- [ ] F-060 AI 행동 트리 (Behavior Tree)
- [ ] F-061 LLM 인터프리터 (메시지 → 캐릭터 행동 매핑)
- [ ] F-062 핀치/멀티터치 인터랙션
- [ ] F-063 본격 방 꾸미기 (가구 배치 자유)

### Deprecated

- ~~F-048 방 꾸미기~~ — F-058 (v2 가구 시스템) + F-063 (v3 본격 방 꾸미기)로 흡수
- ~~F-049~054 Avatar Forge v1 (부품 시스템)~~ — flame 채택으로 폐기. 동일 번호를 flame 마이그 신규 피처에 재사용
- ~~F-027 선물하기 UI (준비중)~~ — MVP 동안 유지, v2.1 F-053로 본격

---

## 영역별 디테일

### 영역 1: Rendering Engine (flame)

#### MVP

```dart
// 채팅방 화면 구조
Scaffold(
  body: Stack([
    GameWidget(game: EncoreCharacterGame()),   // 방 + 캐릭터 (flame)
    DraggableChatPanel(),                       // 기존 채팅 UI (Flutter)
  ]),
)
```

- `EncoreCharacterGame extends FlameGame`
- `RoomWorld extends World` — 방 배경 + 가구 + 캐릭터
- 게임 루프 60fps
- Camera = logical size 480×800, 화면 비율에 맞춰 scale up
- **filterQuality.none** 전제 (도트 그리드 유지)

#### 결정
- ✅ logical size 480×800 (캐릭터 PNG 853×1844는 flame 내부에서 scale)
- ✅ flame 의존성 추가 (`pubspec.yaml`)

#### Open
- Riverpod ↔ flame 상태 동기화 방식 (flame_riverpod 패키지 사용 여부)
- 채팅 메시지 → flame 이벤트 전달 패턴 (EventBus? Provider?)

### 영역 2: Character Component

#### MVP

```dart
class CharacterComponent extends SpriteComponent with TapCallbacks, DragCallbacks {
  late SpriteAnimation breathe;
  CharacterActionType currentAction;

  @override
  void onTapDown(TapDownEvent event) {
    triggerRandomAction();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    checkFurnitureProximity();  // 가구 근처 도달 시 상호작용 트리거
  }
}
```

- Sprite = 액션별 단일 PNG (`character_idle.png`, `character_happy.png`, ...)
- 호흡 = `update()` 안에서 Y position에 sine wave 적용
- 액션 전환 = Sprite swap + 짧은 fade
- 상태머신 = 단순 enum (CharacterActionType: idle/happy/sad/sing/eat/sleep)

#### 결정
- ✅ 액션 enum 그대로 유지 (PR-2에서 결정)
- ✅ 호흡은 직접 `update()` 구현 (SpriteAnimation 아님, 단순함)

#### Open
- 액션 전환 fade 시간 (PR-1에서 280ms였음, 그대로?)
- Sprite swap 시 호흡 위치 reset 여부

### 영역 3: Asset Pipeline

#### MVP
- 현재 GPT 똥쟁이 PNG 6종 그대로 (`mobile/assets/character/character_*.png`)
- 사이즈 853×1844 그대로 (flame이 scale down)

#### v2 (Scenario PoC 통과 시)
- 아이돌별 LoRA 학습 → 액션별 6장 자동 생성
- Supabase Storage 캐싱
- `idol_scenario_models` 테이블 (LoRA 모델 ID, 학습 상태)
- `character_image_urls` JSONB로 액션별 URL 매핑

#### v2 (Scenario PoC 실패 시)
- 외주 도트 아티스트 (1체 30~80만원)
- 첫 시드 5명 = 외주 5체

#### Open
- Scenario PoC 결과 결정 (1주 후)
- 두 트랙 다 가능하게 추상화? 또는 단일 선택?

### 영역 4: Interaction System

#### MVP — 탭 + 드래그

**탭**:
- 탭 시 액션 트리거. MVP 정책: **랜덤 액션 1개 선택 + 모먼트 카드 표시 + 2초 후 idle 복귀**
- 단 sing/eat/sleep은 모먼트 카드와 어울리지 않을 수 있음 → happy/sad만 탭으로 트리거?
- 정책은 PR-F 시점 결정

**드래그**:
- 캐릭터 잡고 끌면 위치 이동
- 화면 경계 안 (방 영역) 으로 제약
- 드래그 종료 시 캐릭터 위치 저장 (백엔드 동기화 — 단 빈도 제한)
- 드래그 중 캐릭터 표정 = idle (또는 살짝 놀란 표정?)

#### v2
- 핀치 줌 (캐릭터 얼굴 가까이)
- 더블탭 = 특정 액션

#### v3
- 멀티터치 (양손 + 회전)

#### Open
- 탭 시 어떤 액션 트리거 (랜덤/순차/상태 기반)
- 드래그 위치 저장 빈도 (실시간 vs 종료 시만)
- 드래그 범위 (방 전체 vs 일부 영역)

### 영역 5: Room + Furniture System

#### MVP — 가구 3~5개 + 위치 기반 상호작용

```dart
class FurnitureComponent extends SpriteComponent {
  final FurnitureType type;   // bed, desk, chair, etc.
  final List<CharacterActionType> triggers;  // 이 가구 근처에서 가능한 액션

  void onCharacterNearby(CharacterComponent character) {
    // 거리 임계값 안에 캐릭터가 있으면 액션 trigger 가능
  }
}
```

**가구 종류 (MVP 3~5개)**:
- 침대 (bed) → 캐릭터 위치 도달 시 sleep 트리거
- 책상 (desk) → eat 트리거 (또는 study 신규)
- 의자 (chair) → 앉기 (idle 변형)
- 추가 2개는 PR-H 시점 결정 (예: 마이크 = sing, 거울 = happy)

**위치 기반 상호작용**:
- 거리 임계값 (예: 50픽셀) 안에 캐릭터가 도달
- 가구별 가능 액션 트리거 (자동 또는 가구 탭 시)
- 모먼트 카드로 시각 알림

#### v2
- 가구 N개 확장 (10~20개)
- 가구 배치 가능 (방 꾸미기 모드)
- 가구 카탈로그 (DB 테이블)

#### v3
- 팬 선물 가구 → 인벤토리
- 본격 방 꾸미기 UI

#### 결정
- ✅ MVP 가구 = Component 단위 (방 배경에 그려진 그림 X)
- ✅ 위치 기반 상호작용 MVP 포함

#### Open
- 가구 PNG 출처 (현재 똥쟁이 방 배경에 가구 그려진 상태 — 별도 PNG로 분리 필요)
- 거리 임계값 정확 수치
- 가구별 가능 액션 매핑 테이블 정의

### 영역 6: Autonomous Behavior

#### MVP — 호흡 + 랜덤 액션

- **호흡**: 항상 ON (sine wave Y position)
- **랜덤 액션**: N초마다 (예: 30~120초 랜덤) 작은 액션 트리거
  - 눈 깜빡임 (별도 sprite or 짧은 fade)
  - 살짝 자세 변경
  - 가만히 있다 살짝 움직임
- 캐릭터가 가구 근처 머무르면 → 가구별 액션 자동 트리거 확률 ↑

#### v2 — 시간대별 행동
- 밤 (22시~6시) → sleep 자동
- 점심 (12시~13시) → eat 자동
- 새벽 (0시~4시) → sleep 깊게
- 기분 상태에 따른 행동 빈도 (기분 ↑ → 자주 움직임)

#### v3 — AI 행동 트리
- Behavior Tree 도입
- 상황 인지 (팬 메시지 빈도, 가구 위치, 시간대, 기분)
- LLM 통합

#### Open
- 랜덤 액션 간격 정확 수치 (너무 자주 = 산만)
- 랜덤 액션 종류 (눈 깜빡임은 별도 sprite 필요)
- v2 시간대 정책 (사용자 timezone 반영)

### 영역 7: LLM ↔ Character Bridge

#### MVP — 없음

#### v2 — 키워드 매칭
- 채팅 메시지에 키워드 감지 ("배고파" → eat, "노래" → sing)
- 백엔드에서 분류 후 flame 이벤트 전달
- 가벼움, LLM 비용 0

#### v3 — LLM 본격
- LLM이 메시지 분석 → 적절한 캐릭터 행동 선택
- 아이돌별 성격 프롬프트
- 비용 추적 (메시지마다 호출 = 비쌈, 캐싱/배치 필요)

#### Open
- 키워드 매칭 룰 정의 위치 (백엔드 코드 vs DB 테이블)
- LLM 호출 비용 예산
- 캐릭터 성격 프롬프트 운영 (아이돌이 직접 작성?)

### 영역 8: Avatar Maker + Customization

#### MVP — 없음 (똥쟁이 1체 고정)

#### v2 — Scenario 기반 메이커 (PoC 통과 시)
- 가입 후 메이커 풀스크린 진입
- 레퍼 이미지 업로드 (1~3장)
- Scenario LoRA 학습 (30분~몇 시간) → 알림
- 메이커 UI: 다양한 옷/머리/표정 변형 N체 생성 → 선택 → 확정
- 부품 조립 X, 단일 PNG 결과

#### v2.1 — 갈아끼우기
- 팬 선물 (옷 / 가구) → 인벤토리
- 아이돌이 갈아끼우기 → 메이커 재진입 or 빠른 교체
- 채팅방 즉시 반영

#### v3 — 본격 커스터마이징
- 가구 + 옷 통합 인벤토리
- 방 꾸미기 본격 UI
- 시즌 한정 아이템

#### Open
- Scenario PoC 결과 (1주 후 결정)
- 메이커 진입점 (가입 후 자동 vs 마이페이지)
- 학습 진행 중 임시 캐릭터 처리

---

## PR 분할 계획

### 정리된 PR (history)

| PR | 처리 | 메모 |
|---|---|---|
| #128 (Avatar Forge v1 스키마) | **머지됨 (2026-06-04). 사용 안 함.** | 별도 PR로 삭제 마이그 예정. PR #130에서 시도됐으나 close (별도 트랙). |
| #129 (character.md docs v1) | **머지됨 (2026-06-04).** | v1은 폐기 대상 (Avatar Forge 기반). 본 PR #131(v2)이 character.md 통째 덮어씀. |

### 신규 PR 트랙 (MVP, flame 마이그)

| PR | 범위 | 결정 의존 | 영역 |
|---|---|---|---|
| **PR-A (docs)** | 본 문서 (character.md v2) 박기 | 본 결정 사항 확정 | 메인 빌더 (정훈) |
| **PR-B (chore)** | flame 패키지 추가, 기본 셋업, `mobile/lib/features/character/game/` 디렉토리 신규 | PR-A 머지 | 클로드코드 |
| **PR-C (feat)** | `EncoreCharacterGame` + `RoomWorld` 골격, 방 배경 렌더링 (PR-1 RoomBackground 이관) | PR-B 머지 | 클로드코드 |
| **PR-D (feat)** | `CharacterComponent` + 액션 PNG 6종 통합, sprite swap | PR-C 머지 + 사이즈 정책 확정 | 클로드코드 |
| **PR-E (feat)** | 호흡 (Y sine wave) + 랜덤 액션 스케줄러 (PR-3 호흡 대체) | PR-D 머지 | 클로드코드 |
| **PR-F (feat)** | 탭 인터랙션 + 액션 트리거 + 모먼트 카드 연동 (PR-4 부분 재활용) | PR-E 머지 + 탭 정책 확정 | 클로드코드 |
| **PR-G (feat)** | 드래그 인터랙션 + 위치 저장 (백엔드 동기화) | PR-F 머지 + 저장 빈도 정책 | 클로드코드 |
| **PR-H (feat)** | `FurnitureComponent` 3~5개 + 위치 기반 상호작용 | PR-G 머지 + 가구 PNG 준비 + 거리 임계값 결정 | 클로드코드 |
| **PR-I (chore)** | 기존 LayeredAvatar / Stack 합성 코드 정리, 사용 안 하는 위젯 제거 | PR-H 머지 | 클로드코드 |

**MVP 머지 후** → 영입 데모 가능 상태 (탭/드래그/가구 상호작용 + 호흡 + 랜덤 액션)

### v2 PR 트랙 (영입 시작 후)

| PR | 범위 |
|---|---|
| PR-V2-A | 시간대별 자율 행동 |
| PR-V2-B | 키워드 기반 LLM 트리거 |
| PR-V2-C | Scenario 메이커 통합 (PoC 통과 시) — 외부 API 통합 + LoRA 학습 큐 + 결과 캐싱 |
| PR-V2-D | 가구 ↔ 캐릭터 본격 상호작용 (가구 N개 확장 + 카탈로그 DB) |
| PR-V2-E | F-045 fan_character_bonds 활용 (누적 성장) |
| PR-V2-F | F-046 시간대별 방 변화 |

### v3 PR 트랙 (본격 차별점)

| PR | 범위 |
|---|---|
| PR-V3-A | Rive 본격 통합 (정밀 모션) |
| PR-V3-B | AI 행동 트리 (Behavior Tree) |
| PR-V3-C | LLM 인터프리터 (메시지 → 캐릭터 행동) |
| PR-V3-D | 핀치/멀티터치 인터랙션 |
| PR-V3-E | 본격 방 꾸미기 (가구 배치 자유) |

---

## Open Questions (정리)

### 기술

1. **Riverpod ↔ flame 상태 동기화** — `flame_riverpod` 패키지 vs 직접 EventBus. PR-B 시점 결정
2. **채팅 메시지 → flame 이벤트 전달** — Provider 구독 vs EventBus. PR-B 시점
3. **flame Camera vs Viewport** — logical size 480×800 어떻게 화면에 맞출지. PR-C 시점
4. **호흡 + 액션 swap sync** — 액션 전환 시 호흡 위치 reset? PR-E 시점
5. **드래그 위치 저장 빈도** — 실시간 vs 종료 시만 vs 5초마다. PR-G 시점
6. **가구별 액션 매핑 테이블** — 코드 vs DB. PR-H 시점

### UX

7. **탭 시 어떤 액션 트리거** — 랜덤 / 순차 / 상태 기반. PR-F 시점
8. **드래그 중 캐릭터 표정** — idle vs 살짝 놀란 표정. PR-G 시점
9. **가구 근처 거리 임계값** — 정확 픽셀 수치. PR-H 시점
10. **랜덤 액션 빈도** — 30초? 60초? 사용자 활동 따라 가변? PR-E 시점

### 에셋

11. **방 배경에서 가구 분리** — 현재 방 배경에 가구 그려진 상태. PR-H 전에 PNG 분리 필요. 정훈 직접 (또는 외주)
12. **눈 깜빡임 sprite** — 별도 PNG 필요? 또는 fade로 대체? PR-E 시점

### Scenario 트랙 (별도)

13. **Scenario PoC 결과** — 1주 후 결정. 통과 → v2 메이커 / 실패 → 외주
14. **본격 출시 시 외주 트랙** — Scenario 통과해도 외주 병행? 정훈 결정

### 운영

15. **본 레포 클로드코드한테 flame 마이그 명령 던지는 방식** — 통째 vs PR 단위. 결정: 통째지만 PR-B 머지 후 정훈 30분 리뷰 안전선
16. **PR-1~4 머지된 코드 정리 시점** — PR-I에서 한 번에 (LayeredAvatar 제거 등)

---

## 엣지 케이스 / 메모

- 캐릭터가 가구 위에 정확히 안 올라가면 어떻게 (스냅? 자유?)
- 드래그 중 채팅창 위로 캐릭터 끌어올리면 어떻게 (Z-order)
- 호흡 + 드래그 동시 진행 시 sync
- flame Game 위젯과 Flutter 채팅창 사이 터치 이벤트 가로채기 충돌
- 랜덤 액션 중 사용자가 탭하면 즉시 멈춤 + 새 액션
- 가구 근처 머무르는 시간 측정 (그냥 지나치는 거 vs 진짜 머무름)
- 호흡 sine wave Y 진폭 (너무 크면 캐릭터가 떠다님)
- 백엔드 통신 끊겼을 때 캐릭터 상태 fallback
- 캐릭터 PNG 로딩 중 placeholder
- 가입 직후 첫 진입 시 캐릭터 등장 애니메이션
- flame 좌표계와 PNG 좌표계 차이 (logical 480×800 vs PNG 853×1844)
- 다양한 화면 비율 (16:9, 19.5:9 등) 대응
- 캐릭터 위치 = 채팅방별 vs 아이돌별 (현재 채팅방마다 다를 가능성)
- 캐릭터 잠금 (다른 아이돌 채팅방에서는 못 만지게)

---

## SPEC.md 로 승격된 항목

확정되어 SPEC.md(계약)로 옮긴 항목 체크.

- [ ] `mobile/lib/features/character/SPEC.md` — F-039~044 (기존 PR-1~4 결과, flame 마이그 후 갱신 필요)
- [ ] `mobile/lib/features/character/game/SPEC.md` (신규) — F-049~054 flame 시스템
- [ ] `backend/app/features/character/SPEC.md` — 기존 character_states 명세 유지 (Avatar Forge v1 시스템은 박은 적 없음)
- [ ] flame 좌표계 표준 (480×800 logical)
- [ ] 가구 매핑 테이블 (가구 ↔ 가능 액션)
- [ ] 랜덤 액션 빈도 / 종류 (PR-E 결정 후)
- [ ] 드래그 위치 저장 정책 (PR-G 결정 후)

---

## 참고

- 노션 회의록: 2026-06-03 정기회의 (안건 2 캐릭터 제작 방안)
- 폐기 검토:
  - Motion Distill (2026-06-04 PoC 결과로 폐기)
  - Avatar Forge v1 부품 시스템 (2026-06-04 비전 재검토로 폐기)
- 폐기된 PR: #128 (Avatar Forge v1 스키마, 머지됨 2026-06-04 — 사용 안 함, 삭제 마이그는 별도 트랙)
- 채택:
  - **flame 게임엔진** (Flutter용 2D 게임엔진)
  - **Scenario.gg PoC** (LoRA 기반 캐릭터 일관성, 별도 트랙)
- 본 문서는 character 슬라이스의 진리원. 갱신 시 날짜 + 결정 명시