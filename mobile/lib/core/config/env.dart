/// 환경변수 — dart-define 우선, flutter_dotenv 폴백.
///
/// 사용:
///   await Env.init();
///   final url = Env.supabaseUrl;
///
/// 빌드:
///   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
/// 또는 .env 파일에 값 채워서 그대로:
///   flutter run
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  /// 앱 부트 시 1회 호출. main()에서.
  static Future<void> init() async {
    // .env 파일 로드 시도. 없거나 실패해도 dart-define으로 fallback.
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Env] .env 미발견. dart-define만 사용.');
      }
    }
  }

  // 주: const String.fromEnvironment는 key가 컴파일타임 상수여야 해서,
  // 헬퍼 함수로 못 빼고 각 getter에서 직접 처리한다.

  // ── Supabase ──
  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    return fromDefine.isNotEmpty ? fromDefine : (dotenv.maybeGet('SUPABASE_URL') ?? '');
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    return fromDefine.isNotEmpty ? fromDefine : (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '');
  }

  // ── 백엔드 API ──
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    return fromDefine.isNotEmpty
        ? fromDefine
        : (dotenv.maybeGet('API_BASE_URL') ?? 'http://localhost:8000');
  }

  // ── Sentry ──
  static String get sentryDsn {
    const fromDefine = String.fromEnvironment('SENTRY_DSN');
    return fromDefine.isNotEmpty ? fromDefine : (dotenv.maybeGet('SENTRY_DSN') ?? '');
  }

  // ── 환경 ──
  static String get env {
    const fromDefine = String.fromEnvironment('ENV', defaultValue: 'dev');
    final fromDotenv = dotenv.maybeGet('ENV');
    return fromDotenv ?? fromDefine;
  }

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';

  /// 필수 값 검증. main()에서 init() 직후 호출 권장.
  static void assertRequired() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (missing.isNotEmpty) {
      throw StateError(
        '필수 환경변수 누락: ${missing.join(", ")}. '
        '.env 또는 --dart-define으로 주입.',
      );
    }
  }
}
