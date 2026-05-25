# F-029 / F-031 notification — 알림 (백엔드)

## 개요

- **F-029 (P2)** 푸시 알림 (수신/뱃지) — 디바이스 토큰 등록/해제 (실제 발송은 본 슬라이스 범위 X, chat_message 등 도메인 슬라이스가 본 슬라이스 공개 인터페이스 경유)
- **F-031 (P1)** 알림 설정 — 인앱 토글 (new_message / idol_reply / marketing) 조회 + 수정

사용자: 팬, 아이돌 (관리자는 본 슬라이스 미사용)

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| POST | `/notification/device-tokens` | FCM 토큰 등록 (멱등) | AuthedUser |
| DELETE | `/notification/device-tokens/{token}` | FCM 토큰 해제 (로그아웃 등) | AuthedUser |
| GET | `/notification/prefs` | 알림 설정 조회 (없으면 default 자동 생성 후 반환) | AuthedUser |
| PATCH | `/notification/prefs` | 알림 설정 부분 수정 | AuthedUser |

### Request/Response

**POST /notification/device-tokens**
```json
// req
{ "token": "fcm-abc...", "platform": "ios" }   // platform: "ios" | "android"
// res 200/201
{ "id": "uuid", "user_id": "uuid", "platform": "ios", "token": "fcm-abc...", "last_used_at": "..." }
```

**GET /notification/prefs / PATCH /notification/prefs**
```json
// PATCH req (부분, 1개 이상)
{ "new_message_enabled": false, "marketing_enabled": true }
// res
{ "new_message_enabled": false, "idol_reply_enabled": true, "marketing_enabled": true, "updated_at": "..." }
```

---

## DB

- **읽기/쓰기**: `device_tokens`, `notification_prefs`, `profiles` (이미 SCHEMA 4.8/4.9, 모델 존재 — `app.shared.models.DeviceToken`, `NotificationPref`)
- **새 컬럼/테이블**: **없음**
- **마이그레이션**: **없음**

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.AuthedUser`
- `core.db.get_session`
- `core.errors.NotFoundError`, `ValidationError`
- `app.shared.enums.DevicePlatform`

다른 피처 호출 X (이 슬라이스는 다른 피처에 호출됨).

---

## 비즈니스 룰

1. **토큰 등록 멱등성**: 같은 `token`이 이미 존재하면
   - 같은 user_id면 `last_used_at = NOW()`만 갱신 (UPDATE)
   - 다른 user_id면 **reassign** (user_id + platform + last_used_at 갱신). 이유: 같은 디바이스에서 계정 전환 시 토큰이 이전 계정에 남으면 잘못 발송됨.
2. **토큰 해제**: 본인 user_id + 토큰 일치하는 row만 삭제. 일치 없으면 멱등 200 (이미 해제됨으로 간주).
3. **prefs lazy create**: GET 호출 시 row 없으면 default(true/true/false) row INSERT 후 반환.
4. **prefs 부분 업데이트**: PATCH 바디에 `null` 또는 누락된 필드는 변경 X. 1개 필드 이상 필수.
5. **본인 데이터만**: 모든 엔드포인트는 `user.id`로만 SELECT/UPDATE/DELETE. RLS도 보호하지만 service 레이어에서도 명시.

---

## 엣지 케이스

- 토큰 빈 문자열 / 200자 초과 → `ValidationError`
- platform이 enum 외 값 → Pydantic 422
- prefs PATCH 바디가 모두 None → `ValidationError` ("변경할 항목이 없습니다")
- 토큰 해제 시 토큰 URL path 인코딩 (FCM 토큰에 `/`, `:` 포함 가능) → router에서 `Path(...)` decode 사용 OR `DELETE /notification/device-tokens?token=...` 쿼리로 받음. **본 SPEC은 쿼리 채택**: `DELETE /notification/device-tokens?token=...`

→ **API 정정**: `DELETE /notification/device-tokens?token=...` (쿼리 파라미터)

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# service.py

async def get_active_tokens_for_user(
    session: AsyncSession, user_id: UUID
) -> list[DeviceToken]:
    """푸시 발송 시 대상 사용자의 모든 활성 FCM 토큰 조회."""

async def is_notification_enabled(
    session: AsyncSession, user_id: UUID, kind: NotificationKind
) -> bool:
    """사용자가 해당 종류 알림을 켜뒀는지. prefs 없으면 default 기준.
    kind: 'new_message' | 'idol_reply' | 'marketing'
    """
```

`NotificationKind`는 `app.shared.enums.NotificationKind` Literal 또는 Enum (본 슬라이스에서 정의 → shared 추가 필요 시 메인 빌더 영역이라 분리 트리거. **본 슬라이스에선 features/notification/schemas.py의 Literal로 정의** 하여 분리 회피).

---

## 수동 테스트 시나리오 (PR 첨부)

1. AuthedUser 로그인 → `POST /notification/device-tokens {token, platform:ios}` → 201 + row 생성
2. 같은 토큰 재등록 → 200 + `last_used_at` 갱신, row 중복 X
3. 다른 user로 같은 토큰 등록 → user_id 갱신 (reassign 검증)
4. `GET /notification/prefs` 첫 호출 → default(true/true/false) row 생성 + 반환
5. `PATCH /notification/prefs {marketing_enabled: true}` → 200 + 해당 필드만 변경
6. `DELETE /notification/device-tokens?token=xxx` → 204
7. 다시 DELETE → 204 (멱등)

기대 결과: 모든 API 본인 데이터만 영향, prefs lazy create, 토큰 reassign 동작.
