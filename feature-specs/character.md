# F-039 ~ F-054 캐릭터 — 요구사항 노트

> ⚠️ **2026-06-08 결정: Avatar Forge 폐기, flame 채택**. 본 문서 상단의 Avatar Forge 관련 결정(2026-06-04)은 **이력 보존용**. 현재 활성 결정은 §2026-06-08 섹션 참조.

> 작업 단위 #13 (캐릭터/육성). 폴더: `features/character` + 메이커 UI는 `features/avatar_forge` 또는 `features/character` 하위.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 → `mobile/lib/features/character/SPEC.md` (+ 신규 `mobile/lib/features/avatar_forge/SPEC.md`, `backend/app/features/character/SPEC.md`) 로 옮긴다.
>
> **2026-06-04**: 회의 + PoC 결과 반영해 **Avatar Forge 방향 채택**. 본 문서 신규 작성.

---

## 한 줄 목표

채팅 위에 아이돌의 도트 캐릭터 + 방을 얹어 "내가 키웠다 / 함께 성장했다"는 육성 서사를 제공한다. 캐릭터는 **아이돌이 직접 마네킹 메이커로 디자인하고, 팬이 선물한 부품으로 시간에 따라 변화하는** 살아 있는 존재.

---

## 컨셉 — Avatar Forge

```
[아이돌 가입]
    ↓
[마네킹 메이커] ← 아이돌이 부위별 부품 선택 (머리/눈/입/옷/신발/액세서리)
    ↓
[데뷔 — 자기 캐릭터 확정]
    ↓
[채팅방에서 캐릭터 등장] ← 호흡 + 상태/표정 + 모먼트 카드
    ↓
[v2.1: 팬이 선물 전송] → [인벤토리에 부품 추가] → [아이돌이 갈아끼우기]
    ↓
[v2.2~v2.3: 방 꾸미기, 시간대별 변화, AI 자동 트리거]
```

**핵심 원칙**:
- 아이돌이 직접 디자인 → 외주비 0 + "내 캐릭터" 정체성
- 부품 조립식 (Slot Forge) → 양산 자동화
- 팬 선물이 시각으로 반영 → 정서적 연결
- 다마고치 본질 유지 — "캐릭터가 그 아이돌"이라는 정체성

---

## 요구사항

### MVP (작업 단위 #13 본체)

- [x] F-039 캐릭터 방 배경 렌더링 — **머지 완료 (PR-1)**
- [x] F-040 정적 캐릭터 + 채팅 오버레이 — **머지 완료 (PR-1, Avatar Forge에서 LayeredAvatar로 재작성 예정)**
- [x] F-041 캐릭터 상태/표정 애니메이션 — **머지 완료 (PR-3, implicit 호흡)**
- [x] F-042 캐릭터 상태 DB + 시간 경과 변화 — **머지 완료 (PR-2)**
- [x] F-043 행동 트리거 인터페이스 (수동) — **머지 완료 (PR-2)**
- [x] F-044 팬 행동→캐릭터 반응 (선물 카드/모먼트) — **머지 완료 (PR-4)**
- [ ] **F-049 Avatar Maker UI (아이돌 전용)** — 마네킹 + 부품 슬롯 선택 + 미리보기 + 저장
- [ ] **F-050 부품 카탈로그** — 글로벌 카탈로그 (자가 조달 PNG 시드)
- [ ] **F-051 아이돌 부품 인벤토리** — default 지급 (MVP)
- [ ] **F-052 슬롯 상태 저장/적용** — 현재 어떤 부품 조합인지. 채팅방 렌더링 트리거

### v2 (별도 작업 단위 후속)

- [ ] F-045 캐릭터 성장 / 누적 상태 — `fan_character_bonds` 활용
- [ ] F-046 시간대별 방 변화 (조명)
- [ ] F-047 AI 문맥 분석 → 행동 자동 트리거 (F-043 IF 재사용)
- [ ] **F-053 선물 → 부품 발송** (v2.1) — F-027 본격 구현, gift 슬라이스 확장
- [ ] **F-054 갈아끼우기 즉시 적용** (v2.1) — 메이커 안 또는 빠른 교체 UI

### Deprecated

- ~~F-048 방 꾸미기~~ — **Avatar Forge에 통합**. 가구도 부품 카테고리의 일종으로 다룸 (v2.3에서 카테고리 추가).
- ~~F-027 선물하기 UI (준비중)~~ — MVP 동안은 "준비중" 유지, v2.1 F-053에서 본격 구현으로 흡수.

---

## 결정 사항 (Decisions)

### 2026-05-29 — Q1 캐릭터 상태 귀속 모델

**스키마는 C(하이브리드), 구현은 A(아이돌 귀속)부터.**
- DB: `character_states`(아이돌 귀속 공유) + `fan_character_bonds`(팬별 유대) 테이블 2개 자리 확보
- MVP: `character_states`만 작동. `fan_character_bonds`는 테이블만 만들고 로직은 v2 (F-045)
- 이유: 아이돌의 "현재 상태"는 공유 정보 → A로 모순 없음. "내가 키운 정도"는 개인 → B/C 필요. 순수 B는 모순 발생

### 2026-05-29 — 렌더링 기술

- 캐릭터 자유 이동·물리·원근법 **제외**
- 정적(F-039/040)은 기술 추가 0 (Flutter Stack)
- AI 자동 트리거(F-047)는 v2로 분리, F-043에서 트리거 IF만 먼저 정의

### 2026-05-29 — UI 레이아웃 (PR-1 후속)

- 검정 배경 자르기 ❌, 방 풀스크린 유지
- 채팅창 반투명 + 위아래 드래그 가능
- 드래그 범위: 최저점 ~55-60%, 최고점 ~15-20%
- 상/하한은 const로 빼서 조정 가능

### 2026-06-04 — Avatar Forge 방향 채택

**회의(6/3) + PoC(6/4) 결과로 채택. Motion Distill 폐기, Slot Forge 진화형으로 확정.**

#### Motion Distill 폐기
- 2026-06-04 PoC: 일러스트 → 픽셀화 파이프라인은 기술적으로 작동
- 미적 결과가 서비스 톤 불일치: "도트 게임 캐릭터"가 아니라 "축소된 일러스트"
- 일러스트 본질(빛/그림자/디테일)과 도트 본질(의도된 픽셀)이 다름
- AI 영상 일관성 검증 단계 진행 불필요 — 시작점이 이미 깨짐

#### Avatar Forge 채택
- 아이돌이 마네킹 베이스에서 직접 캐릭터 디자인 (외주비 0)
- 부품 조립식 양산 (Slot Forge 본질)
- 팬 선물 → 부품 인벤토리 → 갈아끼우기 메커니즘 통합 (v2.1)
- F-027/F-044/F-048 자연스럽게 통합
- 다마고치 본질 유지 — 메이커는 도구일 뿐, 캐릭터 = 아이돌 정체성

### 2026-06-04 — MVP 범위

**MVP = "메이커 + 정적 카탈로그"만.** 팬은 결과만 본다.
- 메이커 UI (F-049) + 부품 카탈로그 (F-050) + 인벤토리 default 지급 (F-051) + 슬롯 상태 (F-052)
- 선물 갈아끼우기(F-053/F-054)는 v2.1
- F-027 선물 UI는 MVP 동안 "준비중" 그대로 유지
- 근거: 메이커가 굴러가지 않으면 선물·갈아끼우기 의미 없음. 핵심 서사 검증이 먼저

### 2026-06-04 — 마네킹 자세 수

**1자세 (idle만)** — 클로드코드 6자세 추천 거부.
- 마네킹 6자세 + 부품 1자세 = eat/sleep/sing 자세에서 옷/머리 어색하게 매달려 보임
- 부품도 6자세로 외주 시 분량 폭증 (27 → 162장)
- MVP는 메이커 작동 검증이 목표. 액션 시각화는 기존 PR-3 호흡 + PR-4 모먼트 카드로 충분
- 액션별 자세는 v2 본격 애니메이션 시점에 재검토

### 2026-06-04 — 부품 조달

**자가 조달 (외주 미진행).**
- 1차 조달 방식: 똥쟁이 마네킹에서 부위별 잘라내기 (A) + GPT 부품 생성 (B) 조합
- A: 핵심 카테고리(머리·옷·신발) 5~10장
- B: 보충 (다른 머리 스타일, 다른 옷 색 등). 똥쟁이 마네킹 첨부로 일관성 유지
- 도구: GIMP / macOS Preview Instant Alpha (A), ChatGPT (B), 필요 시 Piskel·Aseprite (C)
- **목표 분량**: 27장 권장, 16장 최소
- 본격 출시 시점에 외주 발주 (별도 결정 트랙)
- **합의**: MVP 임시 부품은 "시스템 작동 + UX 검증"용. "출시 품질 매력 검증"은 별도 트랙

### 2026-06-04 — 캔버스 사양

- **표준 캔버스 = 853×1844** (현재 머지된 character PNG와 동일)
- 9:19 비율 (모바일 세로형)
- filterQuality.none 전제 (도트 느낌 보존)
- 부품 = 부품 영역만 자른 투명 PNG + anchor 좌표 메타 (JSON)

### 2026-06-04 — DB 스키마

**부품 카탈로그는 컬럼 방식, 슬롯 상태는 JSONB 단일 컬럼.**

```sql
-- 글로벌 부품 카탈로그 (자가 조달 PNG 시드)
character_parts(
  id UUID PRIMARY KEY,
  category ENUM('head','eyes','mouth','top','bottom','shoes','accessory'),
  asset_path TEXT NOT NULL,
  z_index INT NOT NULL,
  anchor_x INT NOT NULL,
  anchor_y INT NOT NULL,
  rarity ENUM('common','rare','epic') DEFAULT 'common',
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
)

-- 아이돌 슬롯 상태 (현재 어떤 부품 조합인지)
idol_character_slot_state(
  idol_id UUID PRIMARY KEY REFERENCES profiles(id),
  slots JSONB NOT NULL DEFAULT '{}',
  -- 예: {"head": "<uuid>", "eyes": "<uuid>", "mouth": "<uuid>", "top": "<uuid>", ...}
  updated_at TIMESTAMPTZ DEFAULT NOW()
)

-- 아이돌별 보유 부품 (MVP는 default 지급, v2.1에서 gift 추가)
idol_part_inventory(
  idol_id UUID REFERENCES profiles(id),
  part_id UUID REFERENCES character_parts(id),
  source ENUM('default','gift') DEFAULT 'default',
  acquired_at TIMESTAMPTZ DEFAULT NOW(),
  gift_from_fan_id UUID NULL REFERENCES profiles(id),
  PRIMARY KEY(idol_id, part_id)
)
```

- 기존 `character_states` (action_type/허기/기분) 그대로 유지. action과 슬롯은 직교
- `fan_character_bonds`는 v2 (F-045)
- 카테고리 확장 시 JSONB라 마이그레이션 불필요 — v2.3 가구 카테고리 추가 시 안정적
- z-order 표준: bottom(10) < top(20) < shoes(30) < head(40) < eyes(50) < mouth(60) < accessory(70)

### 2026-06-04 — 렌더링 기술 확정

**Flutter Stack 사용. Rive/flame 의존성 추가 없음.**
- LayeredAvatarRenderer = Stack에 부품 PNG layered (anchor 좌표 + z-order 적용)
- 기존 PR-3 implicit 호흡(`AnimatedBuilder` + Transform) 그대로 외부에서 한 번에 적용
- 모먼트 카드 sparkle (PR-4) 그대로 호환
- 의존성 0 — pubspec.yaml 변경 없음
- **`docs/FEATURES.md` §8.1 "캐릭터 렌더링 기술 확정 (Rive vs flame)" 미결 항목 → close 가능**
- v2 부품 단위 정밀 애니(옷이 움직임, 머리카락 출렁) 욕심 나면 Rive 재검토 여지는 남김

### 2026-06-04 — 메이커 진입점

**두 진입점 + 자유 수정 (잠금 없음).**
- **첫 진입 (캐릭터 미생성)**: 아이돌 가입 직후 자동으로 메이커 풀스크린. 캐릭터 만들기 전엔 자기 채팅방 진입 불가
- **수정 (캐릭터 있음)**: 자기 채팅방 ⋮ → "캐릭터 디자인" 메뉴
- **잠금 정책**: MVP는 자유 수정. v2.1에서 운영 데이터 보고 잠금 정책(분기당 1회 등) 도입 검토
- 마이페이지에는 진입점 두지 않음 (계정 설정 영역과 결이 다름)

### 2026-06-04 — 신규 피처 번호

- F-049 Avatar Maker UI
- F-050 부품 카탈로그
- F-051 아이돌 부품 인벤토리
- F-052 슬롯 상태 저장/적용
- F-053 선물 → 부품 발송 (v2.1)
- F-054 갈아끼우기 즉시 적용 UX (v2.1)

### 2026-06-04 — PR 분할 (PR-5~PR-9 신규)

§10.1.1 기존 PR-1~4는 머지 완료. 신규 트랙:

| PR | 범위 | 결정 의존 | 영역 |
|---|---|---|---|
| **PR-5** | `character_parts` + `idol_character_slot_state` + `idol_part_inventory` 테이블 + RLS + 시드 | 본 문서 결정사항 확정 | 메인 빌더 (마이그) |
| **PR-6** | parts/slot_state/inventory CRUD API + 기본 카탈로그 시드 | PR-5 머지 | 클로드코드 |
| **PR-7** | mobile repository 확장 + LayeredAvatarRenderer 위젯 + CharacterPlaceholder 교체 | PR-6 머지 + 임시 부품 PNG 일부 준비 | 클로드코드 |
| **PR-8** | `features/avatar_forge/` (또는 `features/character/` sub) — 풀스크린 메이커. 카테고리 탭 + 부품 그리드 + 미리보기 + 저장 | PR-7 + 메이커 UX 와이어 | 클로드코드 |
| **PR-9** | 메이커 진입점 — 첫 진입 자동 풀스크린 + 자기 채팅방 ⋮ "캐릭터 디자인" 메뉴 | PR-8 | 클로드코드 |
| (v2.1) | gift 슬라이스 확장 — 선물 선택지가 카탈로그에서, 전송 시 인벤토리 추가 + 모먼트 트리거 | MVP 검증 후 | 클로드코드 |

---

### 2026-06-08 — flame 채택 + Avatar Forge 폐기

**PoC 결과 + flame 채택으로 Avatar Forge 부품 시스템 폐기.**
2026-06-04 "Flutter Stack / Rive·flame 의존성 추가 없음" 결정을 뒤집음.

#### 폐기 범위
- **F-049** Avatar Maker UI — 폐기
- **F-050** 부품 카탈로그 — 폐기
- **F-051** 아이돌 부품 인벤토리 — 폐기
- **F-052** 슬롯 상태 저장/적용 — 폐기
- **F-053** 선물 → 부품 발송 (v2.1) — 폐기
- **F-054** 갈아끼우기 즉시 적용 UX (v2.1) — 폐기
- **PR-5~PR-9 분할 계획 전체 폐기**
- 부품 자가 조달 (28장) 후처리 — 시각 PoC 일부 사용, 본격 적용 없음

#### 보존
- 기존 머지된 **F-039~F-044** (방 배경 + 정적 캐릭터 6종 + 호흡 + 상태 DB + 행동 IF + 모먼트 카드) — 그대로
- 신규: **flame 기반 렌더링** (F-041 애니메이션 본격 재작업 시 적용)

#### 후속 처리
- **PR-Δ (0006_avatar_forge_drop)**: 0005에서 만든 모든 객체(ENUM + 테이블 3 + 트리거 2 + 함수 1) DROP. 본 PR
- `mobile/assets/character/parts/` + `web/public/character/parts/` 부품 PNG → 삭제 또는 보관 (별도 결정)
- `web/app/dev/avatar-poc/` PoC 페이지 → 삭제 또는 보관 (별도 결정)
- `docs/FEATURES.md §3.8` F-049~F-054 추가 보류 (애초에 §3.8 갱신 안 했음)
- `docs/FEATURES.md §8.1` "캐릭터 렌더링 기술 확정 (Rive vs flame)" 미결 항목 → **flame으로 확정**

#### 새 방향 (별도 작업 단위)
- flame 도입 SPEC 작성 (별도 PR)
- 기존 F-041 호흡(Flutter implicit) → flame 기반 재작업 결정
- 캐릭터 자체는 단일 PNG 패턴 유지 (Avatar Forge 합성 X)

---

## 의문 / 미정 (Open Questions)

### 기술 / UX

1. **z-order 충돌 케이스** — 안경(accessory) vs 머리카락(head). 안경알이 머리카락에 가려지면 안 됨. z-order만으론 안 되는 케이스 발생.
   - 해결안: category × category 예외 테이블 또는 anchor 분리 또는 부품에 sub_z_index 필드
   - 결정 시점: 첫 자가 조달 부품 만들면서 발견되는 케이스 기록 → PR-5/6 진행 중 결정

2. **에셋 캐싱 전략** — 부품 ~27 + 마네킹 = 28장. 채팅방 진입 시 동시 로드 부담 가능
   - 후보: precacheImage 일괄 vs 카테고리별 lazy load vs 슬롯 상태에 포함된 부품만 prefetch
   - 결정 시점: PR-7 LayeredAvatarRenderer 구현 중 성능 보고

3. **저장 경합 처리** — 아이돌이 메이커에서 저장 도중 팬이 선물 보내면 slot_state 업데이트 충돌 (v2.1)
   - 후보: `updated_at` 낙관적 락 vs 트랜잭션 격리
   - 결정 시점: PR-5 스키마 작성 시 (낙관적 락 컬럼 미리 확보)

4. **메이커 진입 장벽** — 27개 부품 × 7 카테고리 처음 보면 위축 가능
   - 후보: 카테고리 탭 + 부품 그리드 + 실시간 미리보기 + "추천 조합 5개" 안내
   - "랜덤 캐릭터 생성" 버튼 (빠른 시작 → 천천히 커스터마이징)
   - 결정 시점: PR-8 메이커 UX 와이어프레임 작업 시

5. **첫 진입 캐릭터 미생성 상태에서 채팅방 접근 차단 UX** — 가입 직후 강제 풀스크린이 거부감 줄 가능성
   - 후보: "캐릭터를 먼저 만들어 주세요" 안내 화면 → "지금 만들기" CTA
   - 결정 시점: PR-9 진입점 작업 시

### 운영 / 비즈니스

6. **갈아끼우기 모먼트 트리거 시점 (v2.1)** — 팬 선물 직후 자동? 아이돌 명시적?
   - 자동 + 모먼트 카드 안내가 자연스럽지만 아이돌 의도 무시 위험
   - 결정 시점: v2.1 진입 직전

7. **본격 출시 시점 부품 외주 발주** — MVP 임시 부품으로 시스템 검증 후, 출시 품질용 부품 외주
   - 결정 시점: MVP 사용자 검증 단계 (아이돌 영입 N명 후)
   - 도트 아티스트 외주 + 톤 일관성 확보 + 27장 → 더 많은 카테고리/스타일 확장

8. **잠금 정책 — 캐릭터 수정 빈도 제한**
   - MVP는 자유 수정. v2.1에서 운영 데이터 보고 정책(분기당 1회 등) 도입 검토
   - "캐릭터를 자주 바꾸면 정체성 약화" 우려 vs 아이돌 자유 보장

---

## 엣지 케이스 / 메모

- 부품 카탈로그에 새 부품 추가될 때 기존 아이돌에게 어떻게 알릴지 (운영 공지? 알림?)
- 부품이 삭제/비활성화되면 그 부품을 입고 있던 아이돌의 슬롯 상태는? (fallback to default? null?)
- 자세별 부품 변형 부재 (MVP) — eat/sleep 자세에서 옷이 어색할 수 있음. 모먼트 카드/표정 변화로 시각 통일 보완
- 호흡 + 부품 동기 — AnimatedBuilder Transform이 LayeredAvatar 외부에서 한 번에 걸려야 sync 유지. 부품마다 별도 Transform 금지
- 마네킹 본체가 부품 z-order 어디에 위치하는가 — 가장 아래(z=0)에 별도 레이어로
- 부품 메타 JSON에 anchor 좌표 외에 "이 부품은 어느 자세에서 어색함" 같은 호환성 플래그 (v2)
- 캐릭터 만들기 전 채팅방 접근 차단 = 아이돌 가입 ↔ idol_signup_applications 승인 사이 흐름과 충돌 가능성. auth 슬라이스와 협의 필요

---

## SPEC.md 로 승격된 항목

확정되어 SPEC.md(계약)로 옮긴 항목 체크.

- [ ] `mobile/lib/features/character/SPEC.md` — F-039~044 (기존 머지된 항목, 본 문서 결정사항으로 갱신 필요)
- [ ] `mobile/lib/features/avatar_forge/SPEC.md` (신규) — F-049 메이커 UI
- [ ] `backend/app/features/character/SPEC.md` (신규) — F-050~052 API
- [ ] API 엔드포인트 명세 — PR-5 스키마 확정 후
- [ ] 읽기/쓰기 테이블 — PR-5 머지 후
- [ ] 공개 인터페이스 — F-052 슬롯 상태 적용 함수, F-049 메이커 진입 함수 등

---

## 참고

- 노션 회의록: 6/3 정기회의 — 안건 2 (캐릭터 제작 방안)
- 폐기 검토: Motion Distill (2026-06-04 PoC로 폐기)
- 흡수 검토: Slot Forge (Avatar Forge에 흡수)
- 본 문서 갱신: 결정사항 추가될 때마다 날짜 + 결정 명시 (`feature-specs/auth.md` 톤 참조)
