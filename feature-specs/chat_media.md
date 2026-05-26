# F-019 / F-020 chat_media — 사진 / 음성 메시지 (요구사항 노트)

> 본 문서는 **진화하는 요구사항 공간**. 자유롭게 적고 수정.
> 확정된 항목은 → `mobile/lib/features/chat_media/SPEC.md` 또는 `backend/app/features/chat_media/SPEC.md` 로 옮긴다.

---

## 한 줄 목표

채팅방에서 팬·아이돌이 **사진 메시지(F-019)** 와 **음성 메시지(F-020)** 를 주고받는다. 1차는 단순 송수신 + 재생까지 (음성→캐릭터 모션 연계는 §7 1차 제외).

---

## 요구사항

### F-019 사진
- [ ] 팬: 사진 1장 선택(갤러리 or 카메라) → 업로드 → `fan_to_idol` 메시지 (`media_type='photo'`)
- [ ] 아이돌: 사진 1장 선택 → 업로드 → `idol_to_fans` broadcast (`media_type='photo'`)
- [ ] 채팅방 리스트에서 사진 메시지 썸네일 노출(없으면 `[사진]` placeholder)
- [ ] 풀스크린 뷰어 (탭하면 확대, 핀치 줌)
- [ ] 업로드 진행률 또는 최소한 로딩 인디케이터

### F-020 음성
- [ ] 팬·아이돌: 마이크 버튼 누르고 있는 동안 녹음 → 떼면 업로드 → 메시지 (`media_type='voice'`)
- [ ] 재생 컨트롤(재생/일시정지, 진행 바, 길이 표시)
- [ ] 채팅방 리스트에서 `[음성]` placeholder (1차)
- [ ] 1차는 단순 재생까지 (캐릭터 모션 연계 X)

### 공통
- [ ] 업로드 실패 시 retry (chat_message의 pending/failed UI 패턴 재사용)
- [ ] 멱등성(`client_message_id`) — 동일 미디어 중복 INSERT 방지
- [ ] RLS: 사진/음성도 chat_message와 동일 RLS (sender_id 검증)

---

## 결정 사항 (Decisions)

- `2026-05-26`: **마이그레이션 불필요** — `messages.media_type` (text/photo/voice) + `media_url` 컬럼 이미 존재 + `messages_media_consistency` CHECK 보유 (text→url null+content not null, photo|voice→url not null).
- `2026-05-26`: **Storage 버킷 = 단일 `chat-media`**, 키 컨벤션 `{idol_id}/{message_id}.<ext>` (Q1=A). RLS 정책 1세트 + signed URL 경로별 발급으로 충분.
- `2026-05-26`: **사진 제한** = 5MB / 장변 2048px / JPEG·PNG·HEIC 입력 → 업로드 전 JPEG로 통일 (Q2). 다운스케일은 클라에서 처리(`flutter_image_compress`).
- `2026-05-26`: **음성 제한** = 60초 / AAC(`m4a`) / 44100Hz mono (Q3). iOS/Android 공통.
- `2026-05-26`: **업로드 경로 = (C) Supabase Storage 직결** (Q4). chat_message/chat_meta와 동일 패턴, backend 0. Storage policy는 messages RLS와 동일 의미로 작성 (업로드: 본인이 sender, 다운로드: 응원 팬 또는 admin).
- `2026-05-26`: **signed URL TTL = 3600초(1시간)** (Q5). 화면 머무는 동안 자연 갱신.
- `2026-05-26`: **권한 미허용 UX** = 거절 시 토스트 + 설정 앱 이동 유도(`permission_handler.openAppSettings`) (Q6).
- `2026-05-26`: **음성 재생 UI = 인라인** (메시지 버블 내 컨트롤) (Q7). 별도 모달은 1차 제외.

---

## 의문 / 미정 (Open Questions)

결정 필요한 사항. SPEC.md로 가기 전 사용자와 정리.

- (없음 — 모두 위로 승격)

---

## 엣지 케이스 / 메모

- 업로드 중 화면 이탈 → 백그라운드 계속 vs 취소? 1차는 **취소** 권장 (단순)
- 사진 메시지 long-press → F-023 답글 (idol_reply, broadcast). 답글의 미디어 자체는 `media_type=text`(내용만)인지, 답글도 사진 가능인지? 1차는 **text only 답글**
- 음성 녹음 중 전화/푸시 인터럽트 → 녹음 취소 + 토스트
- 사진 메시지 삭제(F-026, TBD) 시 Storage 객체도 같이 지워야 하는가? — F-026 작업 시 결정
- 신고(F-033) 시 Storage URL은 admin가 직접 GET 가능해야 함 — service role 사용

---

## 메인 빌더 영역 변경 필요 (분리 트리거 대상)

본 피처는 다음 메인 빌더 영역을 필요로 함. **착수 전 사용자 합의 + 분리 트리거 진행:**

1. **`mobile/pubspec.yaml`** — Flutter dependency 추가 후보:
   - `image_picker` (사진 선택/촬영)
   - `flutter_image_compress` (사진 다운스케일 + JPEG 변환)
   - `record` (음성 녹음)
   - `just_audio` 또는 `audioplayers` (음성 재생)
   - `permission_handler` (카메라/마이크 권한 안내)
2. **iOS `Info.plist`** — `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`
3. **Android `AndroidManifest.xml`** — `RECORD_AUDIO`, `CAMERA` 권한
4. **Supabase Dashboard** — Storage 버킷 `chat-media` 생성 + RLS-equivalent Storage policy (업로드: 본인 sender_id, 다운로드: 응원 팬 또는 admin)
5. **(선택) `docs/SCHEMA.md`** — Storage 정책 섹션 추가 (현재는 없음)

---

## SPEC.md 로 승격된 항목

- [ ] API 엔드포인트 (Q4 결정 후 — 권장 (C)면 0개)
- [ ] 읽기/쓰기 테이블 (messages, message_reads)
- [ ] Storage 버킷 + 키 컨벤션 + signed URL TTL
- [ ] 공개 인터페이스 (mobile: pickAndSendPhoto, recordAndSendVoice, getSignedMediaUrl)
- [ ] 비즈니스 룰

---

## 참고

- 백엔드 SPEC: `backend/app/features/chat_media/SPEC.md` (Q4 결정 후 채움)
- 모바일 SPEC: `mobile/lib/features/chat_media/SPEC.md`
- 전체 피처 명세: [`docs/FEATURES.md`](../docs/FEATURES.md) §3.3 F-019/F-020, §7 1차 제외 (음성→캐릭터 모션)
- DB 스키마: [`docs/SCHEMA.md`](../docs/SCHEMA.md) `messages.media_type/media_url`, `messages_media_consistency`
- 선행 피처 SPEC: `mobile/lib/features/chat_message/SPEC.md` (멱등성/pending/failed UI 패턴 재사용)
