// CaseInterceptor — request/response 변환 통합 테스트.
//
// 실제 네트워크 없이 dio HttpClientAdapter mock으로 검증.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gihagochi/core/api/case_interceptor.dart';

/// HttpClientAdapter mock — 마지막 요청을 기록하고 고정 응답을 돌려줌.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String? lastBody;
  Map<String, dynamic> responseJson = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (requestStream != null) {
      final chunks = <int>[];
      await for (final c in requestStream) {
        chunks.addAll(c);
      }
      lastBody = utf8.decode(chunks);
    }
    final body = utf8.encode(json.encode(responseJson));
    return ResponseBody.fromBytes(
      body,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _buildDio(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(CaseInterceptor());
  return dio;
}

void main() {
  group('CaseInterceptor', () {
    test('request body camelCase → snake_case', () async {
      final adapter = _RecordingAdapter();
      final dio = _buildDio(adapter);

      await dio.post('/users', data: {
        'userName': 'kim',
        'ageYears': 30,
        'nestedObj': {'innerField': 'v'},
      });

      final sent = json.decode(adapter.lastBody!) as Map<String, dynamic>;
      expect(sent, {
        'user_name': 'kim',
        'age_years': 30,
        'nested_obj': {'inner_field': 'v'},
      });
    });

    test('response body snake_case → camelCase', () async {
      final adapter = _RecordingAdapter()
        ..responseJson = {
          'user_id': 'abc',
          'is_active': true,
          'profile_data': {'display_name': 'Kim'},
        };
      final dio = _buildDio(adapter);

      final res = await dio.get('/me');
      expect(res.data, {
        'userId': 'abc',
        'isActive': true,
        'profileData': {'displayName': 'Kim'},
      });
    });

    test('queryParameters도 snake로 변환', () async {
      final adapter = _RecordingAdapter();
      final dio = _buildDio(adapter);

      await dio.get(
        '/idols',
        queryParameters: {'pageSize': 20, 'sortBy': 'newest'},
      );

      expect(adapter.lastRequest!.queryParameters, {
        'page_size': 20,
        'sort_by': 'newest',
      });
    });

    test('Options.extra의 skipCaseTransform=true면 변환 skip', () async {
      final adapter = _RecordingAdapter()
        ..responseJson = {'user_id': 'abc'};
      final dio = _buildDio(adapter);

      final res = await dio.post(
        '/users',
        data: {'userName': 'kim'},
        options: Options(extra: {kSkipCaseTransform: true}),
      );

      // request: 변환 안 됨
      final sent = json.decode(adapter.lastBody!) as Map<String, dynamic>;
      expect(sent, {'userName': 'kim'});
      // response: 변환 안 됨
      expect(res.data, {'user_id': 'abc'});
    });

    test('이미 snake인 키도 idempotent (request)', () async {
      final adapter = _RecordingAdapter();
      final dio = _buildDio(adapter);

      await dio.post('/users', data: {'user_name': 'kim'});

      final sent = json.decode(adapter.lastBody!) as Map<String, dynamic>;
      expect(sent, {'user_name': 'kim'});
    });

    test('List 응답도 재귀 변환', () async {
      final adapter = _RecordingAdapter()
        ..responseJson = {
          'items': [
            {'item_id': 1, 'item_name': 'a'},
            {'item_id': 2, 'item_name': 'b'},
          ],
          'has_more': false,
        };
      final dio = _buildDio(adapter);

      final res = await dio.get('/items');
      expect(res.data, {
        'items': [
          {'itemId': 1, 'itemName': 'a'},
          {'itemId': 2, 'itemName': 'b'},
        ],
        'hasMore': false,
      });
    });

    test('String body는 변환 skip', () async {
      final adapter = _RecordingAdapter();
      final dio = _buildDio(adapter);

      await dio.post(
        '/raw',
        data: 'plain string',
        options: Options(contentType: 'text/plain'),
      );

      expect(adapter.lastBody, 'plain string');
    });
  });
}
