/// 에러 → Sentry 캡처 + 사용자 메시지 매핑.
///
/// 사용:
///   try { ... } catch (e, st) { ErrorHandler.handle(e, st); }
///   final msg = ErrorHandler.userMessage(e);
library;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_error.dart';

class ErrorHandler {
  ErrorHandler._();

  /// 5xx/Unknown은 Sentry로. 4xx 사용자 에러는 캡처 X (노이즈).
  static Future<void> handle(Object error, StackTrace? stackTrace) async {
    if (kDebugMode) {
      debugPrint('[ErrorHandler] $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }

    final shouldCapture = switch (error) {
      ServerError() || UnknownError() => true,
      NetworkError() => false, // 너무 흔함. 캡처하면 노이즈.
      AppError() => false, // 4xx 계열은 사용자 액션
      _ => true, // 분류 안 된 예외는 캡처
    };

    if (shouldCapture) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  /// AppError가 아니면 UnknownError로 감싸서 메시지 추출.
  static String userMessage(Object error) {
    if (error is AppError) return error.userMessage;
    return const UnknownError().userMessage;
  }
}
