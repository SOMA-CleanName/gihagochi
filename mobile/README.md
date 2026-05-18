# mobile/ — gihagochi 모바일 앱

Flutter (iOS + Android) — 팬 + 아이돌 공용.
**Phase 3 완료 상태** — 하네스 (`lib/core/`, `_template/`, `main.dart`) + .env.example 배치됨.
피처 구현은 Phase 6부터 `lib/features/<폴더>/`.

AI 룰: [`AGENTS.md`](./AGENTS.md). 사람 가이드: [`../docs/CONTRIBUTING.md`](../docs/CONTRIBUTING.md).

---

## 폴더 구조

```
mobile/
├── lib/
│   ├── main.dart              # 부트스트랩 (Env/Firebase/Supabase/Sentry/Push init)
│   ├── core/
│   │   ├── config/env.dart    # 환경변수 (dart-define 우선, dotenv 폴백)
│   │   ├── error/             # AppError 계층 + Sentry 핸들러
│   │   ├── storage/           # flutter_secure_storage 래퍼
│   │   ├── api/dio_client     # 백엔드 API + JWT 자동 첨부 + 에러 매핑
│   │   ├── auth/              # Supabase Auth + go_router guard
│   │   ├── realtime/          # idol:<id> 토픽 구독 헬퍼
│   │   ├── push/              # FCM 초기화 + 토큰 등록 hook
│   │   ├── theme/             # Material 3 light/dark + 컬러/텍스트 토큰
│   │   ├── widgets/           # AppButton, AppTextField, Avatar, Loading/Error/Empty, MessageBubble
│   │   └── router/            # go_router + auth_guard 통합
│   └── features/
│       ├── _template/         # 새 피처 복사 베이스 (4-layer: domain/data/application/presentation)
│       └── <피처>/            # Phase 6+
├── pubspec.yaml
└── .env.example
```

> **iOS/Android 플랫폼 폴더 (`android/`, `ios/`)** 는 별도로 생성 필요:
> `flutter create . --platforms=android,ios --org com.gihagochi`
> 기존 `lib/` 파일은 덮어쓰지 않음.

---

## 셋업

### 1. Flutter SDK (3.27+ / Dart 3.8+)

`flutter --version` 으로 확인.

### 2. 플랫폼 폴더 부트스트랩 (최초 1회)

```bash
cd mobile
flutter create . --platforms=android,ios --org com.gihagochi
```

### 3. 의존성 + 코드 생성

```bash
flutter pub get
dart run build_runner build
```

`.g.dart`, `.freezed.dart` 파일들이 생성됨 (gitignored).

피처 작업 중 코드 변경 자주 발생하면 watch:

```bash
dart run build_runner watch
```

### 4. 환경변수

```bash
cp .env.example .env
# .env에 SUPABASE_URL, SUPABASE_ANON_KEY 채움
```

또는 빌드타임 dart-define (시크릿 권장):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://... \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### 5. Firebase 설정 (FCM 사용 시)

- Firebase Console에서 받은 `google-services.json` → `android/app/`
- `GoogleService-Info.plist` → `ios/Runner/`
- 미설치 시에도 앱은 동작 (FCM만 비활성). `main.dart`의 `try/catch` 처리.

### 6. 실행

```bash
flutter run                     # 연결된 디바이스/시뮬레이터
flutter run -d chrome           # 웹 (디버깅용)
```

### 7. 테스트

```bash
flutter test
flutter analyze                 # 정적 분석 (lint)
dart format .                   # 포맷
```

---

## 자주 쓰는 패턴

### Riverpod 2.x (codegen)

```dart
@riverpod
class FooController extends _$FooController {
  @override
  Future<Foo> build() async { ... }
}
```

수정 후 `build_runner` 실행 (또는 watch 중이면 자동).

### go_router 자동 수집

각 피처가 `routes.dart`에서 `List<RouteBase>` export:

```dart
final List<RouteBase> myFeatureRoutes = [GoRoute(...)];
```

`core/router/app_router.dart`에서 import + spread:

```dart
import '../../features/my_feature/routes.dart';
// routes 배열에 ...myFeatureRoutes 추가
```

Dart는 동적 import 없어서 백엔드처럼 100% auto 안 됨. **1줄 추가만**.

### Supabase 직결 vs 백엔드 API

- **읽기 / 단순 INSERT** → Supabase 직결 (RLS 보호)
- **비즈 로직 / 관리자 액션 / fan-out 트리거** → 백엔드 API (dio)

```dart
// Supabase 직결
final rows = await supabase.from('messages').select();

// 백엔드 API
final res = await dio.post('/messages', data: {...});
```

---

## 흔한 이슈

| 증상 | 해결 |
|---|---|
| `Target of URI doesn't exist: '*.g.dart'` | `dart run build_runner build` |
| `Target of URI doesn't exist: '*.freezed.dart'` | 동일 (build_runner) |
| `Firebase has not been correctly initialized` | `google-services.json` / `GoogleService-Info.plist` 누락. Phase 0.2 진행. |
| `MissingPluginException` | 플러그인 추가 후 hot restart 필요 (hot reload X). 또는 `flutter clean && flutter pub get`. |
| iOS Pods 에러 | `cd ios && pod install --repo-update` |
| Android Gradle 에러 | `cd android && ./gradlew clean` (또는 Windows: `.\gradlew clean`) |
| FCM 토큰 안 옴 | Android 13+는 POST_NOTIFICATIONS 권한 필수. `PushService.init()`이 자동 요청하지만 사용자가 거부 가능. |

---

## 다음 단계 (Phase 6+)

```bash
cp -r lib/features/_template lib/features/<폴더>
# SPEC.md → domain → data → application → presentation → routes.dart 순
```

`core/router/app_router.dart`에 1줄 추가 후 `dart run build_runner build` → 끝.

상세: [`AGENTS.md`](./AGENTS.md), [`../docs/CONTRIBUTING.md`](../docs/CONTRIBUTING.md).
