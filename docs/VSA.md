# Vertical Slice Architecture — 설계 정리

> 이 레포가 채택한 **Vertical Slice Architecture (VSA)** 의 정의, 의도, 경계, 트레이드오프를 한 곳에 정리.
> 운영 룰은 [`../AGENTS.md`](../AGENTS.md), 피처 목록은 [`./FEATURES.md`](./FEATURES.md), 라이프사이클은 [`./CONTRIBUTING.md`](./CONTRIBUTING.md).
> 본 문서는 "왜 이렇게 자르는가"와 "슬라이스의 경계가 어디인가"에 집중.

---

## 1. 왜 VSA인가

### 1.1 레이어드 아키텍처를 안 쓰는 이유

전통적 레이어드(`controllers/`, `services/`, `repositories/`, `models/`)는 한 피처를 만지려면 N개 폴더를 모두 만져야 함. 38개 피처 × 평균 4레이어 = **PR마다 충돌 지점이 폴더 전역으로 흩어짐**.

VSA는 같은 피처의 코드를 **한 폴더**에 모은다. 결과:

- 한 피처 = 한 PR = 한 폴더 (격리됨)
- 다른 사람이 다른 피처를 동시에 만져도 git 충돌 0
- AI에게 컨텍스트 줄 때 폴더 하나만 주면 됨 → 토큰 절약 + 환각 감소

### 1.2 이 레포의 제약과 VSA가 맞는 이유

- **팀**: 1명(메인 빌더) + N명(피처 컨트리뷰터). 컨트리뷰터끼리 협의 비용을 0에 가깝게 만들어야 함.
- **AI 보조 코딩**: 한 사람이 한 피처의 **백엔드 + 앱**을 동시에 짠다. 인터페이스 협의 비용 = 자기 자신과 협의 = 0.
- **38개 피처 / 3개 스택**: 레이어로 자르면 폴더당 100개 가까운 파일이 쌓여 탐색 비용 폭증.

→ VSA는 "사람이 만지는 단위(피처)"와 "코드의 폴더 단위"를 일치시키는 전략.

---

## 2. 슬라이스의 정의

### 2.1 한 슬라이스 = 백·앱 한 쌍

```
features/<name>/
├── backend/app/features/<name>/    # 백엔드 슬라이스
└── mobile/lib/features/<name>/     # 앱 슬라이스
```

두 폴더는 **같은 사람이 같은 PR**에 묶어 작성. 같은 `SPEC.md`를 공유.

> 관리자 웹 피처(`F-035`, `F-036`, `F-037`, `F-038`)는 모바일이 없으므로 백엔드 + `admin/app/(admin)/<name>/` 한 쌍.

### 2.2 슬라이스 내부 구조

**백엔드 (`backend/app/features/<name>/`)**

```
SPEC.md       # 명세 (먼저 채움)
router.py     # APIRouter — main.py가 자동 import
schemas.py    # Pydantic 입출력
service.py    # 비즈니스 로직 + DB 접근
tests/        # router 스모크 + 비즈니스 로직 단위 테스트
```

**모바일 (`mobile/lib/features/<name>/`)**

```
SPEC.md            # 백엔드와 동일 명세 공유
routes.dart        # List<RouteBase> 를 export — app_router.dart가 자동 수집
presentation/      # 화면 + 위젯
application/       # Riverpod providers / controllers
domain/            # freezed 모델 (API DTO ≠ domain일 때만)
data/              # repository (dio + Supabase 호출)
```

**관리자 웹 (`admin/app/(admin)/<name>/`)**

```
page.tsx           # Server Component 기본
_components/       # 페이지 전용 컴포넌트
_actions/          # Server Actions (필요 시)
```

### 2.3 슬라이스가 노출하는 것

`SPEC.md`의 **공개 인터페이스** 섹션에 명시된 것만:

- 백엔드: `service.py`의 public 함수 (예: `get_message_by_id(id) -> Message | None`)
- 라우터 엔드포인트는 자동 등록되니 다른 백엔드 슬라이스가 HTTP로 호출할 일은 없음 (직접 import)
- 앱: `routes.dart`의 path 상수 (다른 슬라이스가 navigate 시 사용)

**SPEC.md에 없는 함수/심볼은 다른 슬라이스에서 import 금지.** 슬라이스 내부 구현은 자유롭게 리팩토링 가능해야 함.

---

## 3. 슬라이스의 경계 — 무엇이 슬라이스 안이고, 무엇이 밖인가

### 3.1 슬라이스 **밖** (메인 빌더 영역, 수정 금지)

| 경로 | 책임 |
|---|---|
| `backend/app/core/` | DB 세션, JWT 검증, Supabase/FCM 클라이언트, Realtime broadcast 헬퍼, 에러/로깅 |
| `backend/app/shared/models/` | SQLAlchemy 모델 (테이블당 1파일). 각 파일 상단에 `# OWNER: <feature>` |
| `backend/migrations/` | Alembic 마이그레이션 |
| `mobile/lib/core/` | dio, Supabase Auth/Realtime 래퍼, FCM, theme, 공용 위젯, go_router 루트 |
| `admin/lib/` + `admin/middleware.ts` | Supabase server/client, 인증 미들웨어 |
| `docs/`, `.github/` | 문서 + CI/CODEOWNERS |
| 매니페스트 (`pyproject.toml`, `pubspec.yaml`, `package.json`) | 의존성은 메인 빌더만 추가 |

위는 **호출은 OK, 수정은 X**. 부족하면 사용자(메인 빌더)에게 보고.

### 3.2 슬라이스 **안** (자유 영역)

- 자기 폴더 내 모든 파일
- 자기 `SPEC.md`
- 자기 폴더 내 테스트

### 3.3 회색 지대 — 슬라이스 간 의존

다른 슬라이스의 public 함수를 호출하는 것은 **허용**. 단:

- 호출 대상 슬라이스의 `SPEC.md` "공개 인터페이스" 섹션에 그 함수가 적혀 있어야 함
- 호출 대상 슬라이스의 내부 파일(`service.py` 외 파일)을 직접 import하면 안 됨
- 순환 의존 금지 (A → B 면 B → A 금지)

→ `core/` 의존은 무제한. 다른 `features/` 의존은 SPEC.md 게이트로만.

---

## 4. 자동 등록 — 슬라이스를 "꽂으면 작동"하게

### 4.1 의도

새 슬라이스를 추가할 때 **중앙 파일(main.py, app_router.dart)을 수정하지 않게** 만들어 충돌 지점을 제거.

### 4.2 백엔드 패턴

```python
# backend/app/main.py (메인 빌더가 작성, 컨트리뷰터 수정 X)
import importlib, pkgutil
from app import features

app = FastAPI()
for _, name, _ in pkgutil.iter_modules(features.__path__):
    if name.startswith("_"):  # _template/ 제외
        continue
    module = importlib.import_module(f"app.features.{name}.router")
    if hasattr(module, "router"):
        app.include_router(module.router)
```

규약:
- 각 슬라이스의 `router.py`는 모듈 레벨에 `router: APIRouter` 노출
- `_` prefix 폴더는 무시 (`_template/`)

### 4.3 모바일 패턴

```dart
// mobile/lib/core/router/app_router.dart (메인 빌더 작성)
// 각 features/<name>/routes.dart 가 List<RouteBase> 를 export
final router = GoRouter(routes: [
  ...authRoutes,
  ...chatMessageRoutes,
  // 새 슬라이스 추가 시 import + spread 한 줄
]);
```

> 백엔드는 완전 자동, 모바일은 import 한 줄 수동. Dart는 런타임 리플렉션 제약으로 완전 자동화가 어려움. 비용 대비 합리적 타협.

### 4.4 관리자 웹 패턴

Next.js App Router의 파일 기반 라우팅이 그 자체로 자동 등록. `app/(admin)/<name>/page.tsx` 만들면 끝.

---

## 5. owner 모델 — DB 스키마와 슬라이스의 매핑

### 5.1 테이블 owner

각 DB 테이블은 정확히 **하나의 슬라이스가 owner**. owner는:

- 그 테이블의 스키마 변경(컬럼 추가/인덱스/RLS) 마이그레이션 작성 책임
- 그 테이블에 대한 INSERT/UPDATE/DELETE 비즈니스 로직 보유

다른 슬라이스가 그 테이블에 **읽기**는 가능(RLS 허용 범위 내), **쓰기**는 owner의 public 함수 호출.

`docs/SCHEMA.md`의 owner 컬럼이 진실의 원천.

### 5.2 예시

- `messages` 테이블 owner = `chat_message` 슬라이스
- `chat_meta` 슬라이스가 읽음 통계 계산 시 `messages` SELECT는 OK
- `chat_meta`가 메시지 본문을 UPDATE 하고 싶으면 → `chat_message.service.edit_message()` 호출

### 5.3 마이그레이션 게이트

- PR당 마이그레이션 1개 이하
- 마이그레이션 폴더는 메인 빌더가 CODEOWNERS로 게이트
- 컬럼 추가가 두 슬라이스에서 동시에 일어나면 늦은 PR이 `alembic merge`

---

## 6. SPEC.md — 슬라이스의 계약

슬라이스 작업은 **반드시 SPEC.md부터**. 코드 먼저 X.

```markdown
# F-XXX 기능명

## API
- METHOD /path - 설명

## DB
- 읽기: messages, profiles
- 쓰기: message_reads

## 의존
- core.auth.get_current_user
- core.realtime.broadcast_to_idol_topic
- features.auth.service.get_user_by_id   # 다른 슬라이스 의존은 여기 명시

## 비즈니스 룰
- ...

## 엣지 케이스
- ...

## 공개 인터페이스 (다른 슬라이스가 호출 가능)
- service.get_message_by_id(id) -> Message | None
```

SPEC.md를 먼저 채우면:

- AI에게 컨텍스트 줄 때 SPEC.md + `core/` 인터페이스만 주면 충분
- 백·앱 작업자가 같은 SPEC을 보고 병렬 작업 가능 (한 사람이지만 분리된 시점에)
- 리뷰어가 코드 디테일 안 보고 인터페이스만 봐도 됨

---

## 7. 12개 슬라이스 지도

상세는 [`./FEATURES.md`](./FEATURES.md) §2. 여기선 슬라이스 단위만:

| 슬라이스 | 포함 피처 | 백·앱·관리자 |
|---|---|---|
| `auth` | F-001 ~ F-006 | 백 + 앱 + 관리자(F-036만) |
| `idol_discovery` | F-008, F-009, F-010, F-011 | 백 + 앱 |
| `subscription` | F-012, F-013 | 백 + 앱 |
| `chat_room` | F-007, F-014, F-015, F-016 | 백 + 앱 |
| `chat_message` | F-017, F-018, F-022, F-025, F-026 | 백 + 앱 |
| `chat_media` | F-019, F-020 | 백 + 앱 |
| `chat_meta` | F-021, F-023 | 백 + 앱 |
| `notification` | F-029, F-031 | 백 + 앱 |
| `profile` | F-024, F-028, F-030, F-032, F-034 | 백 + 앱 |
| `report` | F-033, F-037 | 백 + 앱 + 관리자(F-037) |
| `admin` | F-035, F-038 | 관리자 전용 |
| `gift` | F-027 | 앱 전용 (UI만) |

레퍼런스 슬라이스는 `auth` (Phase 6). 다른 슬라이스는 이걸 패턴 복제.

---

## 8. 트레이드오프 / 안티패턴

### 8.1 VSA가 잘 안 맞는 케이스

- **횡단 관심사가 깊을 때**: 인증, 로깅, 모니터링은 슬라이스마다 반복하면 안 됨 → `core/`에 박음
- **공유 도메인 모델**: SQLAlchemy 모델은 여러 슬라이스가 SELECT하므로 `shared/models/`에 둠 (Pydantic 스키마는 슬라이스 안에)
- **트랜잭션이 슬라이스를 가로지를 때**: 예) 응원 시작(`subscription`) + 첫 메시지 자동 전송(`chat_message`). 이때만 한 슬라이스에서 다른 슬라이스의 service 함수를 호출. orchestration은 호출하는 쪽에 둠.

### 8.2 안티패턴

| 안티패턴 | 왜 나쁜가 | 대신 |
|---|---|---|
| 다른 슬라이스의 `service.py` 내부 함수 import | 캡슐화 깨짐. 리팩토링 못함 | SPEC.md의 public 함수만 |
| 슬라이스에서 새 SQLAlchemy 모델 추가 | 다른 슬라이스가 못 봄 | `shared/models/`에 owner 코멘트와 함께 |
| 슬라이스에서 `core/` 수정 | 다른 슬라이스 영향 | 메인 빌더에 요청 |
| 한 PR에 두 슬라이스 변경 | 리뷰 단위 깨짐. 충돌 발생 | 두 PR로 분리 |
| 마이그레이션 2개 PR | merge 시 순서 꼬임 | 한 슬라이스 = 한 마이그레이션 |
| 슬라이스 간 순환 의존 | 빌드 의존 그래프 깨짐 | `core/`로 끌어올리거나 합치기 |

### 8.3 알려진 한계

- **dart 자동 등록 미완**: 모바일은 `app_router.dart`에 import 한 줄 + spread 추가 필요. 완전 자동화 비용 > 이득.
- **테이블 owner 결정의 회색 지대**: 한 테이블을 여러 슬라이스가 비슷한 비중으로 다룰 때(예: `messages`는 `chat_message` / `chat_meta` / `chat_media` 모두 SELECT) — owner는 쓰기 빈도가 높은 쪽 (`chat_message`).
- **`core/` 변경 시 모든 슬라이스 영향**: `core/` 변경 PR은 메인 빌더가 신중하게. 시그니처 변경은 모든 호출 슬라이스 동시 수정 필요.

---

## 9. 관련 문서

- [`../AGENTS.md`](../AGENTS.md) — AI 에이전트 작업 룰 (절대 룰 / 셀프 체크)
- [`./CONTRIBUTING.md`](./CONTRIBUTING.md) — 사람용 라이프사이클 + 환경 셋업
- [`./FEATURES.md`](./FEATURES.md) — 38개 피처 명세 + 12개 슬라이스 매핑
- [`./SCHEMA.md`](./SCHEMA.md) — DB 스키마 + 테이블 owner
- [`./VSA_CHECKLIST.md`](./VSA_CHECKLIST.md) — VSA 관점 체크리스트 (하네스 / 새 슬라이스 / 머지 전)
