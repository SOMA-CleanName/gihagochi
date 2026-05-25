/// F-012 / F-013 subscription — 백엔드 API 호출.
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_client.dart';
import '../domain/subscription_models.dart';

part 'subscription_repository.g.dart';

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(dio: ref.watch(dioProvider));
}

class SubscriptionRepository {
  SubscriptionRepository({required this.dio});

  final Dio dio;

  /// POST /idols/{idolId}/subscribe — 응원 시작 (멱등).
  Future<SubscriptionDetail> subscribe(String idolId) async {
    final res = await dio.post('/idols/$idolId/subscribe');
    return SubscriptionDetail.fromJson(res.data as Map<String, dynamic>);
  }

  /// DELETE /idols/{idolId}/subscribe — 응원 취소 (멱등).
  Future<SubscriptionDetail> unsubscribe(String idolId) async {
    final res = await dio.delete('/idols/$idolId/subscribe');
    return SubscriptionDetail.fromJson(res.data as Map<String, dynamic>);
  }
}
