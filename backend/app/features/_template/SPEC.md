# F-XXX 기능명

> 새 피처 시작 시 이 폴더를 통째로 복사: `cp -r app/features/_template app/features/<폴더>`
> 그 다음 본 파일을 **먼저** 채우고 구현 시작 (AI에게 컨텍스트 줄 베이스).
>
> 주의: `_template`은 폴더명이 `_`로 시작해서 `main.py`의 auto-register에서 **스킵됨**.
> 복사 후 새 폴더명은 `_` 없이 (예: `auth`, `chat_message`).

---

## 개요

한 줄 요약 — 이 기능이 무엇을 하는지.

관련 화면 / 사용자: REQUIREMENTS.md / FEATURES.md 참조.

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| GET | `/template/me` | 예시 — 자기 프로필 조회 | AuthedUser |
| POST | `/template/items` | 예시 — 아이템 생성 | FanUser |

---

## DB

- **읽기**: `profiles`
- **쓰기**: (없음 / 또는 테이블명)
- **새 컬럼/테이블 필요**: (필요 시 메인 빌더와 합의 후 마이그레이션 1개)

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.get_current_user` / `require_role(...)`
- `core.db.get_session`
- (다른 피처 호출 시) `app.features.<other>.service.<public_func>`

---

## 비즈니스 룰

- 룰 1: ...
- 룰 2: ...

---

## 엣지 케이스

- 케이스 1: ... → 처리 방식
- 케이스 2: ... → 처리 방식

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# service.py에서 export하는 public 함수만 명시.
# 여기 명시되지 않은 함수는 다른 피처가 호출하지 말 것 (변경 가능성).

async def get_example(session: AsyncSession, user_id: UUID) -> ExampleResponse: ...
```

---

## 수동 테스트 시나리오 (PR에 첨부)

1. ...
2. ...
기대 결과: ...
