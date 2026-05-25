# F-008 / F-009 / F-010 / F-011 아이돌 탐색 (idol_discovery) — 모바일

> 작업 단위 #2. backend SPEC: [`../../../../backend/app/features/idol_discovery/SPEC.md`](../../../../backend/app/features/idol_discovery/SPEC.md)
> 진화하는 요구사항: [`../../../../feature-specs/idol_discovery.md`](../../../../feature-specs/idol_discovery.md)
>
> 폴더명: `idol_discovery`. `core/router/app_router.dart`에 `idolDiscoveryRoutes` 1줄 import 필요.

---

## 개요

팬이 활성 아이돌 리스트를 무한 스크롤로 탐색하고, 검색바로 stage_name 부분일치 검색하고, 카드 탭으로 상세 화면에 진입해 응원 시작 전 정보를 확인한다. 모든 데이터는 백엔드 API(dio) 경유.

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.2 (F-008 ~ F-011).

---

## 화면 (Routes)

| Route | 화면 | 진입 조건 |
|---|---|---|
| `/discover` | 아이돌 탐색 리스트 (검색바 + 카드 그리드) | 인증된 팬 또는 아이돌 |
| `/discover/:idolId` | 아이돌 상세 (큰 thumbnail + bio + 응원 팬 수 + 응원 시작 placeholder) | `/discover`에서 카드 탭 또는 deep link |

> 회원가입 직후 첫 진입은 `core/router/app_router.dart` 또는 `auth` 슬라이스가 결정.
> 본 슬라이스는 라우트 노출만, 진입 redirect 룰은 메인 빌더 영역.

---

## 의존 화면 / 데이터

- **화면 진입 경로**: 메인(`/main`) 또는 가입 직후 redirect → `/discover` (auth/core가 결정)
- **읽기**: 백엔드 API
  - `GET /idols?q=&page=&page_size=` → 리스트 + 페이지네이션
  - `GET /idols/{id}` → 상세
- **쓰기**: 없음 (응원 시작/취소는 subscription 슬라이스)
- **Realtime 구독**: 없음
- **Supabase 직결**: 없음

---

## 의존 (core)

- `core.api.dio_client.dio` — 백엔드 API 호출 (JWT 자동 첨부)
- `core.auth.auth_service` — 인증 상태 (필요 시)
- `core.router.app_router` — route 등록 (1줄 import 추가만)
- `core.widgets.*` — 공용 위젯 (Avatar, LoadingView, ErrorView, EmptyView)
- `core.error.error_handler` — 에러 표시

> 다른 슬라이스 호출 없음. subscription 슬라이스는 이후 합류 시점에 본 슬라이스의 상세 화면 안에서 응원 버튼을 추가하거나, subscription 슬라이스가 별도 위젯으로 끼워넣음 (TBD).

---

## 비즈니스 룰

- 검색바 디바운스: 입력 후 300ms 대기 후 호출
- 무한 스크롤: 리스트 하단 도달 시 다음 페이지 자동 호출 (`has_more=true`일 때)
- 검색어 변경 시 페이지 초기화 (page=1)
- 검색 결과 0건 → empty state ("검색 결과 없음" + 검색어 표시)
- 상세 진입 시 응원 팬 수 / 응원 여부를 매번 fresh 조회 (캐시 없음)
- 상세 화면의 응원 버튼은 placeholder ("응원하기" 버튼 — 클릭 시 토스트 "준비 중"). subscription 슬라이스 합류 시 실제 액션 연결
- 본인이 그 아이돌 본인일 때(`is_subscribed=false`이고 id 같음) 응원 버튼 비활성 또는 미노출

---

## 엣지 케이스

- **검색 도중 빠른 입력 (디바운스 race)**: 마지막 입력 결과만 표시. 이전 응답은 무시.
- **무한 스크롤 마지막 페이지 + 사용자가 더 스크롤**: 로딩 인디케이터 없이 그대로
- **존재하지 않는 idol_id로 deep link 진입**: 404 → ErrorView ("아이돌을 찾을 수 없습니다") + 뒤로가기 버튼
- **정지된 아이돌 deep link**: 404 (백엔드가 활성 조건으로 자동 제외)
- **dio 401**: core dio interceptor가 세션 클리어 + 로그인 화면 redirect
- **dio 5xx / 네트워크**: ErrorView + 재시도 버튼

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// 없음. idol_discovery는 leaf — 다른 슬라이스가 호출하지 않음.
// subscription 슬라이스가 상세 화면에서 응원 버튼을 띄울 때는 본 슬라이스의 idolId만 알면 됨.
```

---

## 수동 테스트 시나리오 (PR 첨부)

### 시나리오 1: 탐색 리스트 골든 패스
1. 팬으로 로그인 → `/discover` 진입
2. **기대**: 활성 아이돌 카드 리스트, activated_at 최신순, 카드에 stage_name + thumbnail + bio 요약

### 시나리오 2: 검색
1. 검색바에 일부 stage_name 입력
2. **기대**: 300ms 후 부분 일치 결과만 표시 (case-insensitive)
3. 검색어 지움 → 전체 리스트 복귀

### 시나리오 3: 무한 스크롤
1. 페이지 끝까지 스크롤
2. **기대**: 다음 페이지 자동 로드. has_more=false면 더 이상 호출 안 함.

### 시나리오 4: 카드 탭 → 상세
1. 카드 탭 → `/discover/{id}` 진입
2. **기대**: 큰 thumbnail, bio 전문, 응원 팬 수 표시, "응원하기" placeholder 버튼

### 시나리오 5: 검색 결과 0건
1. 존재하지 않는 검색어 입력
2. **기대**: "검색 결과 없음" empty state

### 시나리오 6: 정지된 아이돌 deep link
1. (사전) admin에서 한 아이돌 정지
2. `/discover/{정지된_id}` deep link 진입
3. **기대**: ErrorView 404
