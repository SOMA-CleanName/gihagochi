# QA 체크리스트 — 1차 실기 테스트

> 1차 작업 단위 12개 머지 완료 (2026-05-27) 후 실기 QA 가이드.
> 시나리오는 [`docs/FEATURES.md`](./FEATURES.md) §2 작업 단위 순서로 정렬.
> 버그 발견 시 GitHub Issue (`bug` 라벨) 등록 → fix PR.

---

## 1. QA 환경 준비

### 1.1 디바이스

| 항목 | 검증 대상 | 비고 |
|---|---|---|
| **Android (필수)** | Galaxy S22 / Android 16 | 개발 기준 디바이스 |
| Android (권장) | 중급기 (Android 12~13), 폴드/플립 | 호환성 |
| **iOS (필수)** | iPhone 12+ / iOS 14+ | APNs + Sign in with Apple, TestFlight 권장 |
| 네트워크 | Wi-Fi / LTE 둘 다 | Realtime 끊김 시 재연결 검증 |

### 1.2 QA 계정 (dev DB)

미리 만들어둘 것:

1. **팬 계정 1** (이미 존재 — `tpgus0510@gmail.com`)
2. **팬 계정 2** — Realtime 멀티유저 검증용, 다른 Google 계정 필요
3. **아이돌 계정 1~2** — mock seed 의 `idolA` / `idolB` 활용 가능, 또는 신규 가입 + 관리자 승인
4. **관리자 계정** — 관리자 웹 검증용 (`role=admin` profile)

### 1.3 빌드 종류

| 빌드 | 명령 | 용도 |
|---|---|---|
| debug | `flutter run -d <id>` | UX 검증, hot reload, DevOverlay 노출 |
| **release** | `flutter run --release -d <id>` | **출시 시점에 가까운 검증 — 성능 + tree-shake** |
| iOS TestFlight | `xcodebuild` + App Store Connect | APNs / Sign in with Apple 종단 |

### 1.4 모니터링 미리 켜기

- **Sentry** — 현재 DSN 403 에러 (잘못된 키). dev 프로젝트 DSN 설정해서 크래시/에러 자동 수집
- **Supabase Dashboard** — Auth / Database / Storage / Realtime 각 탭 동시 모니터링
- **Logcat (Android) / Console.app (iOS)** — 다트 stacktrace + 네이티브 권한 로그

### 1.5 dev DB 검증 도우미 (asyncpg 헬퍼)

QA 진행 중 자주 필요한 작업 — 본 레포의 `backend/.venv` + asyncpg 로 즉시 실행:

| 시나리오 | 명령 / SQL |
|---|---|
| 메시지 60개 일괄 INSERT (페이지네이션 검증) | (스크립트 별도 작성 권장) |
| subscription 토글 (응원 / 취소) | `UPDATE subscriptions SET unsubscribed_at = NOW() WHERE ...` |
| profile.deleted_at 복구 (탈퇴 복구) | `UPDATE profiles SET deleted_at = NULL WHERE id = '...'` |
| idol_signup_applications 상태 토글 | `UPDATE idol_signup_applications SET status = 'rejected', rejection_reason = '...' WHERE ...` |
| 메시지 Realtime broadcast 시드 | `INSERT INTO messages (type, sender_id, idol_id, content, media_type) VALUES ('idol_to_fans', '<idol>', '<idol>', '테스트', 'text');` |

→ **권장: `backend/scripts/qa_seed_*.py` 헬퍼 모음 추가** (한 줄 명령으로 시드/리셋).

---

## 2. 시나리오 체크리스트

각 시나리오 = 1 row. 빌드 (debug / release) × OS (Android / iOS) 매트릭스로 PASS / FAIL / N/A + 노트 기록 권장 (시트 또는 Notion).

### 2.1 인증 (auth · F-001~006)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| A1 | 신규 Google OAuth 가입 (팬) | display_name + 약관 동의 → `/main` 진입 |
| A2 | 아이돌 가입 → 관리자 승인 대기 → 거절 → 재신청 | 거절 사유 표시, 재신청 가능 |
| A3 | 자동 로그인 (앱 재시작) | 동일 화면 복귀 (auth_guard 통과) |
| A4 | 토큰 만료 (refresh 실패) | `/auth/landing` 강제 이동 |
| A5 | 로그아웃 (마이페이지) | `/auth/landing` 즉시 이동 |
| A6 | 다른 Google 계정 로그인 (`prompt=select_account`) | 매번 계정 선택 화면 노출 (PR #55) |

### 2.2 프로필 / 마이페이지 (profile · F-007/024/028/030/032/034)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| P1 | `/main` 진입 (응원 0명) | 빈 상태 + "아이돌 추가" CTA → `/discover` |
| P2 | `/main` 진입 (응원 N명) | 채팅방 카드 N장, 최근 메시지 미리보기 |
| P3 | 마이페이지 진입 | 프로필 카드 + 4 섹션 (응원 / 알림 / 계정 / 약관) |
| P4 | 팬 프로필 편집 (display_name + avatar) | 갤러리 권한 → 5MB 초과 차단 / JPEG·PNG 외 차단 / 저장 즉시 반영 |
| P5 | 아이돌 프로필 편집 (stage_name + bio + thumbnail) | stage_name unique 위반 시 토스트 |
| P6 | 회원 탈퇴 (계정·보안) | `deleted_at` UPDATE + `/auth/landing` 이동 (DB 확인) |
| P7 | 약관 / 개인정보 / 고객센터 | placeholder 페이지 정상 표시 + 이메일 복사 |
| P8 | **F-024 아이돌 본인 채팅방 진입** | 아이돌이 자기 `/chat/<self_id>` 진입 시 isActiveSubscription 자동 통과 (PR #59) |

### 2.3 아이돌 탐색 (idol_discovery · F-008~011)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| D1 | `/discover` 전체 리스트 | 활성 idol 만 노출 (suspended 제외) |
| D2 | 검색 (활동명) | 부분 일치 |
| D3 | 필터/정렬 | UI 동작 |
| D4 | 아이돌 상세 페이지 (F-011) | 정보 + 응원 시작 버튼 |

### 2.4 응원 (subscription · F-012/013)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| S1 | 응원 시작 | `/main` 카드 추가됨 |
| S2 | 응원 취소 (마이페이지 또는 채팅방 메뉴) | 카드 사라짐 + 채팅방 진입 차단 |
| S3 | 이미 응원 중인 아이돌 재진입 | 정상 진입 |

### 2.5 채팅방 (chat_room · F-014~016)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| R1 | 카드 탭 → 채팅방 진입 | AppBar (thumbnail + 활동명 + ⋮ 메뉴) + 메시지 + 입력 |
| R2 | 카드 롱프레스 → 메뉴 BottomSheet | gift / 응원 취소 / 신고 / 알림 끄기 액션 (다른 피처가 끼움) |
| R3 | 응원 안 한 아이돌 직접 URL 진입 | 차단 + 토스트 |
| R4 | suspended 아이돌 진입 | 차단 메시지 |
| R5 | 시간 표시 ("방금 전" / "n분 전") | 자연스러움 |
| R6 | pull-to-refresh | 카드 재조회 |

### 2.6 메시지 (chat_message · F-017/018/022/025/026)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| M1 | 텍스트 전송 (팬→아이돌) | optimistic 즉시 표시 → 확정 |
| M2 | 빠른 연속 전송 (5개) | 순서 유지, sending 상태 단계 |
| M3 | 네트워크 오프라인 전송 | ⚠️ 표시 + 탭으로 재전송 |
| M4 | **Realtime broadcast 수신** | 다른 디바이스/세션에서 아이돌이 발행 → 즉시 도착 |
| M5 | 카드 미리보기 자동 갱신 | 채팅방 → `/main` → 카드 텍스트 = 최신 메시지 |
| M6 | 페이지네이션 | 60+ 메시지 시드 후 위로 스크롤 → 추가 50개 로딩 |
| M7 | **F-025 아이돌 발행** | 본인 = idol → 같은 입력창에서 broadcast (type=idol_to_fans) |
| M8 | **F-026 수정** | 본인 메시지 롱프레스 → 수정 → "수정됨" 라벨 |
| M9 | **F-026 삭제** | 본인 메시지 롱프레스 → 삭제 → "(삭제된 메시지)" placeholder |
| M10 | 사진/음성 메시지 도착 | chat_media 위젯 정상 렌더링 |

### 2.7 미디어 (chat_media · F-019/020)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| MD1 | 사진 메시지 전송 | 갤러리 권한 → 업로드 → 표시 |
| MD2 | 사진 5MB 초과 / 비-JPEG·PNG | 차단 토스트 |
| MD3 | 음성 메시지 녹음 | 마이크 권한 → 녹음 → 업로드 → 재생 |
| MD4 | 음성 재생 (상대 메시지) | 정상 재생 |
| MD5 | 미디어 메시지가 카드 미리보기에 `[사진]` / `[음성]` 라벨 | 정상 |

### 2.8 읽음 / 답글 (chat_meta · F-021/023)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| MT1 | 채팅방 진입 시 last_read_at 갱신 | DB 확인 (`subscriptions.last_read_at`) |
| MT2 | 카드 안 읽은 카운트 표시 | 정상 |
| MT3 | 아이돌이 fan_to_idol 메시지에 답글 (F-023) | reply composer (롱프레스) → 답글 broadcast (parent_message_id 설정) |
| MT4 | 답글 메시지 표시 (모든 팬 공개) | 원본 메시지 미리보기 + 답글 본문 |

### 2.9 알림 (notification · F-029/031)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| N1 | 신규 가입 후 FCM 토큰 등록 | 백엔드 DB `device_tokens` 확인 |
| N2 | OS 알림 권한 거부 → 인앱 안내 | graceful degrade |
| N3 | 백그라운드 메시지 도착 | 푸시 알림 표시 |
| N4 | 포그라운드 메시지 (iOS) | 알림 + 화면 즉시 갱신 (PR #51) |
| N5 | 알림 설정 토글 (마이페이지) | 인앱 토글 → 백엔드 반영 |

### 2.10 신고 (report · F-033/037)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| RP1 | 채팅방 메뉴 → "신고" | 신고 모달 → 사유 선택 → 제출 |
| RP2 | 관리자 웹 신고 큐 확인 | 신고 표시 |
| RP3 | 관리자 처리 (무시/삭제/경고/정지) | 각 액션 결과 검증 |

### 2.11 선물 (gift · F-027)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| G1 | 채팅방 메뉴 → "선물하기" | 준비 중 모달 표시 (UI only) |

### 2.12 관리자 (admin · F-035/036/038)

| # | 시나리오 | 기대 동작 |
|---|---|---|
| AD1 | 관리자 웹 로그인 (관리자 권한) | role=admin 인증 |
| AD2 | 가입 신청 큐 (대기/승인/거절) | 액션 결과 |
| AD3 | 사용자 정지/해제 | `profiles.status` 갱신 |
| AD4 | 신고 처리 큐 | 4종 액션 |

---

## 3. QA 방식 권장

### 3.1 매트릭스 + 직접 실행

위 체크리스트를 row, 디바이스(Android / iOS) × 빌드(debug / release) 를 column 으로 매트릭스화. 1셀당 PASS / FAIL / N/A + 노트.

### 3.2 멀티유저 검증 (Realtime 핵심)

가장 어려운 부분 — **2대 이상의 디바이스 필요**:
- 디바이스 A (팬 계정) — 채팅방 진입 + 머무름
- 디바이스 B (아이돌 계정) — 메시지 발행
- → A 화면에 즉시 도착하는지

**대안 (디바이스 1대만)**: 디바이스 A 채팅방 진입 후 → PC 에서 SQL 로 INSERT. Realtime 이벤트 검증.

### 3.3 데이터 시드 / 리셋 자동화

QA 진행 중 자주 필요한 작업은 헬퍼 스크립트로:

- 메시지 60개 일괄 INSERT (페이지네이션)
- subscription unsubscribe (차단 검증)
- profile.deleted_at 복구 (탈퇴 복구)
- 사진/음성 메시지 시드

→ **`backend/scripts/qa_seed_*.py` 헬퍼 모음 작성 권장**.

### 3.4 버그 발견 시 양식

GitHub Issue (`bug` 라벨) 본문 권장 양식:

| 항목 | 내용 |
|---|---|
| 시나리오 # | 위 체크리스트 ID (예: M4 — Realtime broadcast 수신) |
| 디바이스 / OS | Android 16 / iOS 17 |
| 빌드 | debug / release |
| 재현 단계 | 1. ... 2. ... 3. ... |
| 기대 동작 | |
| 실제 동작 | |
| 스크린샷 / 로그 | |

→ fix PR 시 issue 번호 `Closes #NN`.

### 3.5 시간 부족 시 우선순위

1. **인증 + 프로필** (모든 사용자 경로의 진입점)
2. **chat_message 종단** (Realtime + optimistic + 페이지네이션 + 수정/삭제)
3. **chat_media** (네이티브 권한 + 업로드)
4. **notification** (iOS APNs 까다로움)
5. **admin** (관리자 웹 별도 빌드)
6. **나머지**

### 3.6 종단 회귀 시나리오 (Smoke Test)

5분 짜리 빠른 검증 — 매 빌드 / 출시 후에도 반복:

1. 신규 가입 (Google) → `/main` → `/discover` → 아이돌 응원
2. 채팅방 진입 → 메시지 전송 → 받기 (다른 세션 또는 SQL)
3. 메시지 수정 / 삭제
4. 사진 메시지 1개
5. 마이페이지 → 로그아웃 → 자동 로그인 차단 확인

---

## 4. 출시 전 필수 후속 작업

QA 통과 후에도 출시 전 별도 처리 필요. ([`docs/FEATURES.md`](./FEATURES.md) §8.1 참조)

- 약관 / 개인정보 처리방침 실제 문안 (placeholder 교체)
- Supabase **prod 프로젝트** 분리 (현재 dev 만)
- `0002_storage_rls` / `0003_realtime_publication` migration prod 적용
- 회원 탈퇴 30일 후 hard delete cron
- 약관 버전 변경 시 재동의 모달
- Apple Sign in with Apple (다른 소셜 추가 시 App Store 가이드라인 4.8)

---

## 5. 참고

- [`docs/FEATURES.md`](./FEATURES.md) — 38개 피처 + 12개 작업 단위 매핑
- [`docs/TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) — 운영 중 마주친 함정들
- [`docs/ARCHITECTURE.md`](./ARCHITECTURE.md) — 시스템 구조 (작성 예정)
- [`AGENTS.md`](../AGENTS.md) — AI 에이전트 작업 룰
