# mobile/AGENTS.md — Flutter stack 룰

루트 [`AGENTS.md`](../AGENTS.md)의 절대 룰은 그대로. 이 파일은 **모바일 stack-specific**.

---

## Stack

- **Flutter 3.27+** / **Dart 3.8+** (Material 3)
- **Riverpod 3.x** (`@riverpod` 어노테이션 + codegen, `riverpod_annotation 4.x`)
- **freezed 3.x** (불변 모델 + JSON 직렬화 — `abstract class` 필수)
- **go_router 14.x** (라우팅 + redirect)
- **dio 5.x** (백엔드 API)
- **supabase_flutter 2.x** (Auth + Realtime + Storage 직결)
- **firebase_messaging 15.x** + **flutter_local_notifications 18.x** (FCM)
- **sentry_flutter 8.x**

## Run

```bash
flutter pub get
dart run build_runner watch   # ★ 작업 중 항상
flutter run                                                # 디바이스 실행
flutter test                                               # 테스트
flutter analyze                                            # lint
dart format .
```

---

## 폴더 구조

```
mobile/lib/
├── main.dart           # 부트스트랩. 수정 시 메인 빌더 합의.
├── core/               # 인프라. 수정 시 메인 빌더 합의.
└── features/
    ├── _template/      # 복사 베이스 (라우터 자동 등록 X — 수동 import)
    └── <피처>/         # ★ 작업 영역
```

피처 내부 구조 (4-layer vertical slice):

```
<피처>/
├── SPEC.md
├── routes.dart                       # List<RouteBase> export
├── domain/<이름>_model.dart          # freezed 불변 모델
├── data/<이름>_repository.dart       # Supabase/dio 호출
├── application/<이름>_controller.dart # Riverpod AsyncNotifier
└── presentation/<이름>_screen.dart   # ConsumerWidget
```

---

## 새 피처 시작

```bash
cp -r lib/features/_template lib/features/<폴더>
# 폴더명은 _ 없이.
```

그 후 `core/router/app_router.dart`에:

```dart
import '../../features/<폴더>/routes.dart';
// routes 배열에 ...<폴더>Routes spread
```

→ `dart run build_runner build` → 끝.

순서: **SPEC.md → domain → data → application → presentation → routes.dart**

---

## ★ 코드 생성 (build_runner)

**작업 중 watch를 항상 켜둬라.** 안 그러면 `Target of URI doesn't exist: '*.g.dart'` 빨간 줄.

```bash
dart run build_runner watch
```

`.g.dart` (riverpod + json_serializable), `.freezed.dart` (freezed)는 gitignored. 로컬에서만 생성.

`part 'filename.g.dart';` / `part 'filename.freezed.dart';` 선언이 freezed/riverpod 코드에 필수.

---

## Riverpod 2.x 패턴

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'my_controller.g.dart';

@riverpod
class MyController extends _$MyController {
  @override
  Future<List<MyModel>> build() async {
    final repo = ref.watch(myRepositoryProvider);
    return repo.fetchAll();
  }

  Future<void> create(String title) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(myRepositoryProvider).create(title: title);
      return ref.read(myRepositoryProvider).fetchAll();
    });
  }
}
```

- **`@riverpod`** — 일반 provider. dispose 시 자동 정리.
- **`@Riverpod(keepAlive: true)`** — 앱 라이프타임 (auth, supabase client, dio 등)
- **`AsyncValue.guard`** — 예외를 AsyncError로 변환

화면에서:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myControllerProvider);
    return state.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: ...),
      data: (items) => ListView(...),
    );
  }
}
```

---

## freezed 모델

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
abstract class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String title,
    DateTime? createdAt,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

---

## Supabase 직결 vs 백엔드 API

| 케이스 | 어디로 |
|---|---|
| 단순 SELECT, 본인 데이터 조회 | Supabase 직결 (RLS 보호) |
| INSERT 후 비즈 룰/사이드 이펙트 필요 | 백엔드 API (dio) |
| 관리자 액션 | 백엔드 API |
| Storage 업로드 | Supabase 직결 |
| Realtime 구독 | Supabase 직결 |
| fan-out 트리거 메시지 발행 | 백엔드 API (or DB trigger가 처리) |

```dart
// Supabase 직결 — JWT는 supabase_flutter가 자동
final client = ref.watch(supabaseProvider);
final rows = await client.from('messages').select();

// 백엔드 API — JWT는 dio 인터셉터가 자동 첨부
final dio = ref.watch(dioProvider);
final res = await dio.post('/messages', data: {...});
```

---

## 라우팅 (go_router)

각 피처는 `routes.dart`에서 `List<RouteBase>` export.

`core/auth/auth_guard.dart`의 `_publicRoutes` 세트에 인증 안 필요한 경로 추가.

화면 이동: `context.go('/path')` (replace) / `context.push('/path')` (stack 추가).

---

## 에러 처리

```dart
import '../../../core/error/app_error.dart';
import '../../../core/error/error_handler.dart';

try {
  await repo.create(...);
} catch (e, st) {
  await ErrorHandler.handle(e, st);   // Sentry 캡처 (5xx/Unknown만)
  rethrow;                             // controller가 AsyncError로 잡음
}
```

UI는 `state.when(error: ...)` → `ErrorView(error: e, onRetry: ...)` 사용.

`ErrorView`가 자동으로 `ErrorHandler.userMessage(e)`로 한국어 메시지 표시.

---

## 푸시 (FCM)

- `main.dart`에서 `PushService.init()` 호출 — 권한 요청 + 토큰 발급 + foreground 표시까지 자동
- 토큰을 백엔드 `device_tokens` 테이블에 저장하는 책임은 **features/notification**에서:
  ```dart
  await PushService.init(registrar: (token, platform) async {
    await dio.post('/notifications/tokens', data: {'token': token, 'platform': platform});
  });
  ```

---

## 테스트

```bash
flutter test                                # 전체
flutter test test/widget_test.dart          # 특정
```

Riverpod controller / repository는 단위 테스트 권장. 위젯 테스트는 핵심 화면만.

```dart
testWidgets('홈 진입 시 로딩 → 데이터', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [myRepositoryProvider.overrideWithValue(FakeRepo())],
      child: const MaterialApp(home: MyScreen()),
    ),
  );
  // ...
});
```

---

## 흔한 함정

- **`*.g.dart` / `*.freezed.dart` 빨간 줄** → `build_runner watch` 안 켜져 있음
- **`Target of URI doesn't exist`** → 새 파일 만들고 build_runner 아직 안 돌림
- **StatefulWidget 도배** → Riverpod 쓰는데 setState 쓰는 건 안티패턴. ConsumerWidget + provider로
- **provider in widget build로 매번 new** → `ref.watch(provider)` 사용 (provider는 자동 캐시)
- **`MaterialApp` 두 개** → `MaterialApp.router` 한 개만 (`main.dart`에). 화면은 `Scaffold`
- **routes.dart import 누락** → 새 피처 추가 후 `app_router.dart`에 1줄 추가 잊으면 라우트 등록 X
- **Firebase 미설치 환경 빌드 깨짐** → `main.dart`의 try/catch가 graceful degrade. google-services.json/Info.plist 없어도 앱 실행됨 (푸시만 X)
- **iOS Pods 캐시 문제** → `cd ios && pod install --repo-update`
- **권한 누락 (마이크/카메라/알림)** → `ios/Runner/Info.plist` + `android/app/src/main/AndroidManifest.xml` 수정 필요. 메인 빌더 합의 후.

---

## 의존성 추가 필요 시

`pubspec.yaml`은 메인 빌더 영역. 새 패키지 필요하면 **메인 빌더에게 핑** (사용 이유 + 대안 검토).

이미 박혀있음: dio (HTTP), supabase_flutter (DB/Auth/Realtime/Storage), riverpod (상태), go_router (라우팅), freezed (모델), cached_network_image (이미지), image_picker/cropper (사진), record/audioplayers (음성), firebase_messaging (푸시), sentry_flutter (모니터링).

### ⚠ analyzer 8.4 lock 주의

Flutter 3.41 SDK 일부인 `leak_tracker_flutter_testing 3.0.10`이 `analyzer 8.4.0`을 강제. 그래서 codegen 패키지는 analyzer 8.x 호환되는 마지막 버전에 lock됨:

- `freezed: ^3.2.3` (3.2.5는 analyzer 9 요구 — ✗)
- `riverpod_generator: ^4.0.0` (4.0.3는 analyzer 9 요구 — ✗)
- `json_serializable: ^6.11.2` (6.14는 analyzer 10 요구 — ✗)
- `mockito` 추가 시 반드시 `^5.6.4` (5.6.5는 analyzer 13 요구 — ✗)
- `drift`, `auto_route`, `injectable` 최신은 모두 analyzer 9~10 요구 → **현재 사용 불가**. local DB는 sqflite, DI는 Riverpod로 대체.
- `retrofit_generator`는 analyzer 8.4 지원 — 추가 가능.

`flutter pub upgrade --major-versions`로 codegen 무심코 올리면 resolution 깨짐. 새 패키지 추가 전 메인 빌더와 호환성 확인.
