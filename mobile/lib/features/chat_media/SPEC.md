# F-XXX 기능명

> 새 피처 시작 시 이 폴더 통째 복사: `cp -r lib/features/_template lib/features/<폴더>`
> 그 다음 본 파일을 **먼저** 채우고 구현 시작 (AI 컨텍스트 베이스).
>
> 폴더명은 `_` 없이 (예: `auth`, `chat_message`). 그 후 `core/router/app_router.dart`에
> `import` + `...<폴더>Routes` 1줄 추가 (Dart는 동적 import 없어서 수동).

---

## 개요

한 줄 요약 — 이 화면이 무엇을 하는지.

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` 참조.

---

## 의존 화면 / 데이터

- **화면 진입 경로**: 어디서 어떻게 진입하는지
- **읽기**: Supabase 직결 (RLS 보호) — `messages`, `profiles`
- **쓰기**: 백엔드 API (FastAPI 라우터 경유) — 예: `POST /messages`
- **Realtime 구독**: 예: `idol:<id>` 토픽

---

## 의존 (core)

- `core.api.dio_client.dio` (백엔드 호출)
- `core.auth.auth_service.supabaseProvider` (Supabase 직결)
- `core.realtime.realtime_service` (필요 시)
- `core.widgets.*` (UI 공용)

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

```dart
// repository.dart 또는 controller의 public 메서드만 명시.
// 여기 없는 함수는 다른 피처가 호출하지 말 것.

Future<Message?> getMessageById(String id);
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. ...
2. ...
기대 결과: ...
