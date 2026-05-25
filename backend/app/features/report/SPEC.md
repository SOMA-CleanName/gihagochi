# F-033 / F-037 report — 신고 (백엔드)

## 개요

- **F-033** (P1) 신고하기 — 팬이 부적절 메시지 신고 (자유 입력 reason)
- **F-037** (P1) 관리자 신고 처리 — dismissed/message_deleted/warned/suspended

차단 기능은 1차 범위 X (제품 헌법 #6).

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| POST | `/reports` | 신고 생성 (중복/자기 신고 차단) | FanUser |
| GET | `/admin/reports?status=pending&page=1&page_size=20` | 관리자 큐 (pending only 1차) | AdminUser |
| POST | `/admin/reports/{report_id}/resolve` | 처리 (status='handled' + action 기록) | AdminUser |

### Request/Response

**POST /reports**
```json
// req
{ "message_id": "uuid", "reason": "욕설 포함된 메시지입니다." }
// res 201 → ReportDetail
```

**POST /admin/reports/{id}/resolve**
```json
// req
{ "resolution_action": "warned", "resolution_note": "1차 경고" }
// resolution_action: "dismissed" | "message_deleted" | "warned" | "suspended"
// resolution_note: optional, ≤500자
// res 200 → ReportDetail
```

---

## DB

- **읽기**: `reports`, `messages` (sender_id 검증용), `profiles`
- **쓰기**: `reports` (INSERT, UPDATE)
- **새 컬럼/테이블**: **없음** (SCHEMA 4.7, `Report` 모델 존재)
- **마이그레이션**: **없음**

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.FanUser`, `AdminUser`
- `core.db.get_session`
- `core.errors.NotFoundError`, `ValidationError`, `ConflictError`
- **`app.features.admin.service.suspend_user`** (resolution_action='suspended' 시 호출 — admin 슬라이스 공개 인터페이스)

---

## 비즈니스 룰

1. **중복 신고 차단**: 같은 reporter_id + message_id → ConflictError (DB UNIQUE + service 사전 검증).
2. **자기 메시지 신고 차단**: `message.sender_id == reporter_id` → ValidationError.
3. **메시지 존재 검증**: NotFoundError.
4. **resolve 멱등 X**: 이미 `status='handled'`인 report 재처리 → ConflictError.
5. **resolve side effect 점진 적용**:
   - `dismissed` / `warned`: status 갱신만 (warned 누적은 reports 집계로 — SCHEMA 4.7)
   - `suspended`: status 갱신 + **`admin.service.suspend_user(target=message.sender_id, reason=resolution_note ?? '신고 처리')` 호출**
   - `message_deleted`: status 갱신만. **실제 메시지 삭제는 chat_message 슬라이스 머지 후 후속 PR로 wire** (TBD).
6. **resolve 트랜잭션**: status 갱신 + side effect는 동일 트랜잭션 (atomic).

---

## 엣지 케이스

- reason 빈 문자열 → 422 (Field min_length=10)
- reason 500자 초과 → 422
- resolution_action enum 외 값 → 422
- resolve 시 target user(message.sender_id)가 이미 정지된 상태 + action='suspended' → admin.suspend_user의 멱등 동작 (status=='suspended'면 그대로). 본 슬라이스는 변경 X.
- message가 RESTRICT FK로 보호 — 삭제 차단됨 (정상)

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# service.py — 다른 피처에서 import 가능

async def get_warned_count_for_user(
    session: AsyncSession, target_user_id: UUID
) -> int:
    """대상 사용자가 받은 'warned' 처리 카운트. 자동 정지 정책 도입 시 admin이 호출."""
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. FanUser로 `POST /reports {message_id, reason}` → 201 + ReportDetail
2. 같은 fan이 같은 message 다시 신고 → 409 ConflictError
3. 자기 메시지 신고 → 400 ValidationError
4. AdminUser로 `GET /admin/reports?status=pending` → 페이지 응답
5. AdminUser로 `POST /admin/reports/{id}/resolve {action:'warned'}` → status='handled', resolution_* 채워짐
6. 같은 report 재 resolve → 409
7. `action:'suspended'` 처리 → admin.suspend_user 호출되어 target user status='suspended'

기대 결과: 중복/자기 차단, 처리 멱등 X, suspended는 실제 정지 트랜잭션 묶임.
