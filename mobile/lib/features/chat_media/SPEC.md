# F-019 / F-020 chat_media — 사진 / 음성 메시지 (모바일)

## 개요

채팅방에서 팬·아이돌이 **사진**(F-019) / **음성**(F-020) 메시지를 주고받는다. 1차는 단순 송수신 + 인라인 재생까지 (음성→캐릭터 모션은 §7 1차 제외).

본 슬라이스는 **mobile only + Supabase Storage 직결** (chat_meta 패턴 — backend 0). Storage 버킷 `chat-photo / chat-voice` + Storage policy + RLS가 권한을 보장한다.

---

## 의존 화면 / 데이터

- **화면 진입 경로**: `chat_message`의 입력창(사진/마이크 버튼) + 메시지 버블(사진/음성 콘텐츠 렌더링)에서 본 슬라이스의 공개 위젯/함수를 호출. 본 슬라이스는 별도 라우트 없음.
- **읽기**: Supabase Storage `chat-photo / chat-voice` 버킷의 signed URL (다운로드)
- **쓰기**:
  - Supabase Storage `chat-photo / chat-voice/{idol_id}/{message_id}.<ext>` PUT (업로드)
  - Supabase Postgres `messages` INSERT (sender 컨텍스트, RLS 보호)
- **Realtime 구독**: 없음 (`chat_message`가 처리)

---

## 의존 (core)

- `core.auth.auth_service.supabaseProvider` (Supabase 직결 — Storage + Postgres)
- `core.widgets.*` (없으면 인라인)

다른 피처의 공개 인터페이스도 사용:
- `chat_message/domain/message.dart` — `Message`, `MessageType`, `MediaType`
- `chat_message/application/uuid.dart` — `generateUuidV4` (client_message_id)

---

## Storage 정책 (Supabase Dashboard 영역, 사용자 수동 작업)

본 슬라이스 동작 전제. AGENTS 절대 룰 1로 Dashboard 작업은 사용자 수행.

- **버킷명**: `chat-photo / chat-voice`
- **public**: `false` (signed URL로만 접근)
- **키 컨벤션**: `{idol_id}/{message_id}.{ext}` — `{ext}` ∈ `jpg`, `m4a`
- **Storage policy** (의미):
  - INSERT: 인증 사용자, 키 prefix `{auth.uid()}` 또는 본인이 sender인 메시지의 idol_id prefix 허용
  - SELECT: 응원 중인 fan (`is_subscribed_to(idol_id)`) 또는 admin
- **signed URL TTL**: 3600초 (1시간)

(상세 SQL은 `feature-specs/chat_media.md` 또는 별도 Supabase 작업 노트)

---

## 비즈니스 룰

1. **사진 메시지 (F-019)**
   - 입력: 1장 (갤러리 또는 카메라). 1차는 다중 선택 X.
   - 업로드 전 다운스케일: 장변 2048px, JPEG, 최대 5MB (`flutter_image_compress`).
   - 송신 시퀀스: (1) 클라가 `message_id` 생성 (`generateUuidV4`) → (2) `chat-photo / chat-voice/{idol_id}/{message_id}.jpg` 업로드 → (3) `messages` INSERT (sender 역할에 맞춰 `type` 결정: 팬=`fan_to_idol`, 아이돌=`idol_to_fans`. `media_type='photo'`, `media_url=<storage path>`).
   - Storage 업로드 실패 → ValidationError. messages INSERT 실패 → ValidationError + 업로드 객체 cleanup 시도 (best-effort).
2. **음성 메시지 (F-020)**
   - 입력: 마이크 버튼 hold-to-record (최대 60초). 떼면 자동 업로드.
   - 포맷: AAC `m4a`, 44.1kHz mono, bitrate 64kbps.
   - 송신 시퀀스: 사진과 동일하되 확장자 `m4a` / `media_type='voice'`.
   - 1차는 재생만 (캐릭터 모션 X).
3. **수신 표시**
   - `media_type='photo'`: 썸네일 버블 (탭하면 풀스크린 뷰어).
   - `media_type='voice'`: 인라인 재생 컨트롤 (재생/일시정지 + 진행 바 + 길이).
   - `media_url`은 Storage 경로(`{idol_id}/{message_id}.jpg`). 화면에서 signed URL 발급 후 렌더링. signed URL은 1시간 TTL — 화면 머무는 동안 충분.
4. **권한**
   - 사진 갤러리/카메라: `image_picker`가 자체 권한 요청. 거절 시 `permission_handler.openAppSettings()` 안내.
   - 마이크: `record`가 자체 권한 요청. 동일 안내.

---

## 엣지 케이스

- **업로드 중 화면 이탈**: 1차는 업로드 cancel (단순). 백그라운드 유지 X.
- **권한 거절**: 토스트 + 설정 이동 버튼 (`permission_handler.openAppSettings()`).
- **HEIC 입력**: `flutter_image_compress`가 JPEG로 자동 변환.
- **음성 녹음 중 인터럽트** (전화/푸시): 녹음 stop + 업로드 취소 + 토스트.
- **5MB 초과 사진**: 다운스케일 후에도 초과 시 ValidationError ("사진이 너무 큽니다").
- **60초 초과 음성**: 자동 stop + 그 시점까지 업로드.
- **signed URL 만료**: 화면 다시 진입 시 재발급 (FutureBuilder 패턴).
- **삭제된 메시지**: `Message.deletedAt != null` → chat_message가 이미 placeholder 처리. 본 슬라이스 노출 X.

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// data/chat_media_repository.dart

/// Storage 경로(`{idol_id}/{message_id}.jpg`)를 받아 signed URL 발급. TTL 1시간.
Future<String> getSignedMediaUrl(String storagePath, {int expiresInSeconds = 3600});

/// 사진 메시지 송신. 갤러리/카메라로 1장 선택 → 다운스케일 → 업로드 → messages INSERT.
/// 사용자 취소(no pick) 시 null 반환.
Future<Message?> pickAndSendPhoto({
  required String idolId,
  required ImageSource source,  // ImageSource.gallery | ImageSource.camera
});

/// 음성 메시지 송신. 이미 녹음된 로컬 파일 path를 받아 업로드 → messages INSERT.
/// hold-to-record UI는 VoiceRecorderButton이 담당.
Future<Message> sendVoiceMessage({
  required String idolId,
  required String localFilePath,  // record 패키지가 출력한 m4a 경로
});

// presentation/photo_picker_sheet.dart

/// 사진 picker BottomSheet (갤러리 / 카메라 / 취소). chat_message가 입력창에서 호출.
Future<void> showPhotoPickerSheet(BuildContext context, {required String idolId});

// presentation/voice_recorder_button.dart

/// hold-to-record 마이크 버튼. chat_message 입력창에서 사용.
class VoiceRecorderButton extends ConsumerStatefulWidget {
  const VoiceRecorderButton({super.key, required this.idolId});
  final String idolId;
}

// presentation/photo_message_bubble.dart

/// 메시지 버블 — 사진 썸네일. 탭 시 풀스크린 뷰어로 push.
class PhotoMessageBubble extends ConsumerWidget {
  const PhotoMessageBubble({
    super.key,
    required this.storagePath,
    required this.isMine,
    required this.createdAt,
  });
}

// presentation/voice_message_bubble.dart

/// 메시지 버블 — 음성 인라인 재생 컨트롤.
class VoiceMessageBubble extends ConsumerStatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.storagePath,
    required this.isMine,
    required this.createdAt,
  });
}

// routes.dart
List<RouteBase> get chatMediaRoutes; // 빈 리스트 (모달/위젯만, 라우트 없음)
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. 팬으로 채팅방 진입 → 입력창 카메라 버튼 → 갤러리에서 사진 1장 → 업로드 → `fan_to_idol` 메시지 표시
2. 동일 채팅방에 본인이 보낸 사진이 썸네일로 보이고, 탭하면 풀스크린 뷰어
3. 마이크 버튼 hold → "녹음 중" UI → 떼면 업로드 → `voice` 메시지 인라인 재생 가능
4. 아이돌 계정으로 사진 1장 송신 → `idol_to_fans` broadcast → 다른 응원 팬 화면에 노출 확인
5. 60초 초과 음성 시도 → 자동 stop + 60초까지만 업로드
6. iOS 시뮬레이터에서 카메라 권한 거절 → "설정에서 권한 허용" 안내 + 설정 앱 이동 동작
7. 사진 메시지 미리보기(채팅방 리스트)에 `[사진]` placeholder + 마지막 음성에 `[음성]` 노출

기대 결과: 모든 시나리오 통과, `messages_media_consistency` CHECK 위반 0, RLS reject 0 (정상 흐름).
