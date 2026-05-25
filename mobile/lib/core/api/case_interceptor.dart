/// dio request/response의 JSON key 케이스 자동 변환.
///
/// - request body: Dart camelCase → 백엔드 snake_case
/// - response body: 백엔드 snake_case → Dart camelCase
///
/// 모델에서 `@JsonKey(name: 'snake_case')` 어노테이션 제거 가능.
/// 기존 모델(snake_case 매핑 어노테이션 있음)과 충돌하므로 본 인터셉터는
/// `camelDioProvider`에만 attach. 기존 `dioProvider`는 무영향.
///
/// Opt-out: 특정 요청에서 변환을 끄려면
///   `Options(extra: {kSkipCaseTransform: true})`
library;

import 'package:dio/dio.dart';

import 'case_converter.dart';

/// `Options.extra`에 본 키로 `true`를 넣으면 해당 요청만 변환 skip.
const String kSkipCaseTransform = 'skipCaseTransform';

class CaseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isSkipped(options) || !_isJsonRequest(options)) {
      handler.next(options);
      return;
    }
    final data = options.data;
    // FormData / String / null / 바이너리는 변환 skip — Map / List만.
    if (data is Map || data is List) {
      options.data = convertKeys(data, camelToSnake);
    }
    // queryParameters도 변환 (백엔드 라우터가 snake_case일 수 있음).
    if (options.queryParameters.isNotEmpty) {
      options.queryParameters = Map<String, dynamic>.from(
        convertKeys(options.queryParameters, camelToSnake) as Map,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (_isSkipped(response.requestOptions)) {
      handler.next(response);
      return;
    }
    final data = response.data;
    if (data is Map || data is List) {
      response.data = convertKeys(data, snakeToCamel);
    }
    handler.next(response);
  }

  bool _isSkipped(RequestOptions options) {
    final raw = options.extra[kSkipCaseTransform];
    return raw is bool && raw;
  }

  bool _isJsonRequest(RequestOptions options) {
    final ct = options.contentType ?? options.headers['Content-Type']?.toString();
    if (ct == null) return true;
    return ct.toLowerCase().contains('application/json');
  }
}
