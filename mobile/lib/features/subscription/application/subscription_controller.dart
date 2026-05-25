/// F-012 / F-013 subscription — 액션 controller.
///
/// 본 슬라이스는 독립 화면 없음. 호출 측 슬라이스(예: idol_discovery 상세)가
/// subscribe / unsubscribe 호출 후 본인 controller invalidate.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/subscription_repository.dart';
import '../domain/subscription_models.dart';

part 'subscription_controller.g.dart';

@riverpod
class SubscriptionController extends _$SubscriptionController {
  @override
  Future<SubscriptionDetail?> build() async => null;

  /// 응원 시작. 결과는 state로 노출됨.
  /// 호출 측은 await 후 본인 controller invalidate.
  Future<SubscriptionDetail?> subscribe(String idolId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.subscribe(idolId);
    });
    return state.asData?.value;
  }

  /// 응원 취소.
  Future<SubscriptionDetail?> unsubscribe(String idolId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(subscriptionRepositoryProvider);
      return repo.unsubscribe(idolId);
    });
    return state.asData?.value;
  }
}
