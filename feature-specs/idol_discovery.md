# F-008 / F-009 / F-010 / F-011 아이돌 탐색 — 요구사항 노트

> 작업 단위 #2 (아이돌 탐색). 폴더: `features/idol_discovery`.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 →
> `backend/app/features/idol_discovery/SPEC.md` + `mobile/lib/features/idol_discovery/SPEC.md` 로 옮긴다.

---

## 한 줄 목표

팬이 **승인된 활성 아이돌 목록을 탐색·검색·필터**하고, **상세 화면에서 응원 시작 전 정보를 확인**할 수 있게 한다.

---

## 요구사항

### F-008 탐색 리스트
- [ ] 활성 아이돌(`idol_profiles` 존재 + `profiles.role='idol' AND status='active'`) 만 노출
- [ ] 회원가입 직후 첫 진입 화면 + 메인의 "아이돌 추가하기" 진입 시 동일 화면 사용
- [ ] 카드/리스트: stage_name, thumbnail, bio 요약 표시
- [ ] 페이지네이션 (스크롤 끝 → 다음 페이지)

### F-009 검색
- [ ] `stage_name` 부분 일치 검색 (case-insensitive)
- [ ] 검색어 비어있으면 전체 리스트와 동일
- [ ] (1차 제외) bio 검색, 태그 검색 — 운영 데이터 누적 후

### F-010 필터/정렬
- [ ] **1차 = 정렬만**. 필터 항목은 운영 데이터 보강 후 결정 (TBD)
- [ ] 기본 정렬: 활성화 최신순 (`activated_at DESC` — SCHEMA.md 인덱스에 이미 존재)
- [ ] (추후) 인기순(응원 팬 수), 알파벳순 등

### F-011 상세
- [ ] stage_name, bio 전문, thumbnail (큰 사이즈), activated_at
- [ ] 응원 팬 수 (subscriptions count) — 1차 포함
- [ ] 현재 사용자의 응원 여부 표시 (응원 시작/취소 버튼 분기) — 단, 응원 액션 자체는 subscription 슬라이스
- [ ] (1차 제외) 활동 이력, 메시지 미리보기 — chat 슬라이스 합류 후

---

## 결정 사항 (Decisions)

- `2026-05-25`: **백엔드 API 제공** (옵션 c — 혼합). 단순 SELECT라도 백엔드를 두면 검색/정렬/필터 비즈룰을 한 곳에서 통제 가능 + 향후 추천 알고리즘 확장 여지. 모바일은 dio로 백엔드 호출.
  - 대안 (직결만)도 가능하지만 RLS만으론 활성 조건(role+status+idol_profiles 존재) 한 번에 필터링 어렵고 향후 정렬/추천 로직 분산.
- `2026-05-25`: **활성 아이돌 정의** = `idol_profiles` row 존재 AND `profiles.role='idol'` AND `profiles.status='active'` AND `profiles.deleted_at IS NULL`. 본 슬라이스 모든 쿼리의 베이스.
- `2026-05-25`: **검색 = stage_name 부분 일치만** (1차). PostgreSQL `ILIKE '%q%'`. case-insensitive. 향후 trigram/full-text search 검토.
- `2026-05-25`: **정렬 = `activated_at DESC` 고정** (1차). SCHEMA.md 인덱스 그대로 활용. 추후 추천 알고리즘 도입 시 정렬 옵션 확장.
- `2026-05-25`: **필터는 1차 범위 외**. F-010 "필터 항목 운영 데이터 보강" TBD 유지. API는 sort/q 파라미터만 받음.
- `2026-05-25`: **페이지네이션 = offset/limit, 20행/페이지**. cursor 페이지네이션은 데이터 규모 커지면 검토.
- `2026-05-25`: **상세 페이지 응원 여부 표시는 본 슬라이스에서 처리** (subscription 슬라이스 호출 X 가능). `subscriptions` 테이블 SELECT 1건으로 충분. 응원 시작/취소 액션 자체는 subscription 슬라이스가 처리.
- `2026-05-25`: **상세 페이지 응원 팬 수 = 1차 포함**. 단순 COUNT 쿼리. 캐시는 향후.
- `2026-05-25`: **모바일은 백엔드 API + dio 사용** (Supabase 직결 X). 일관성.
- `2026-05-25`: **공개 인터페이스 = 없음 (leaf)**. 다른 슬라이스가 호출할 일 없음 (subscription도 본인 idol_id 알면 직접 처리). 본 슬라이스는 mobile UI 전용.

---

## 의문 / 미정 (Open Questions)

1. **상세 페이지 응원 팬 수 노출 형식** — 정확한 숫자 vs "100+" 같은 라운드. 1차는 정확한 숫자, 운영 후 조정.
2. **활성화 직후 vs 일정 노출 지연** — 승인 직후 즉시 탐색 노출 vs N일 후 노출 (운영 정책). 1차는 즉시.
3. **검색 결과 0건 UX** — 단순 empty state vs "검색어 추천" / "근접 아이돌" 추천. 1차는 empty state.
4. **회원가입 직후 첫 진입과 메인의 "아이돌 추가하기" 진입 시 화면 동일 vs 분기** — 동일 화면 + 진입 경로별 헤더 텍스트만 다르게? Mobile 결정.

---

## 엣지 케이스 / 메모

- 정지된 아이돌(`status='suspended'`)은 리스트에서 즉시 사라져야 함 — 베이스 쿼리의 `status='active'` 조건이 처리
- 탈퇴한 아이돌(`deleted_at IS NOT NULL`)도 같은 방식으로 자동 제외
- 검색어에 SQL injection 가능한 특수문자 — ILIKE 파라미터 바인딩으로 안전
- 검색어가 매우 긴 경우 — 200자 제한 (백엔드 schema validation)
- 상세 페이지에서 본인이 아이돌 본인 프로필 진입 시 — 응원 버튼 비활성 또는 미노출 (subscription 슬라이스가 처리하므로 본 슬라이스는 표시 데이터만)
- 같은 stage_name 중복 — UNIQUE 제약이라 발생 X
- 페이지네이션 중 새 아이돌 활성화 시 같은 row가 다음 페이지에 중복될 수 있음 — 1차는 무시, cursor 페이지네이션 도입 시 해결

---

## SPEC.md 로 승격된 항목

- [x] 백엔드 API 엔드포인트 (GET /idols, GET /idols/{id})
- [x] 읽기 테이블 (idol_profiles, profiles, subscriptions)
- [x] 공개 인터페이스 = 없음 (leaf 명시)
- [x] 비즈니스 룰 (활성 정의, 검색 방식, 정렬)
- [x] 엣지 케이스

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#2 아이돌 탐색), §10.1
- 피처 상세: `docs/FEATURES.md` §3.2
- DB 스키마: `docs/SCHEMA.md` (`idol_profiles` §4.3, `profiles` §4.1, `subscriptions` §4.4)
- 선행 슬라이스: admin SPEC (`backend/app/features/admin/SPEC.md`) — `idol_profiles` INSERT가 거기서 처리됨
- 후속 슬라이스: subscription (응원 시작/취소 액션), chat_room (응원 후 진입)
