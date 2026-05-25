/// F-031 알림 설정 — prefs controller.
///
/// 화면은 build() 결과 watch. 토글 변경 시 optimistic update + 실패 시 백엔드 응답으로 복구.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/notification_repository.dart';
import '../domain/notification_models.dart';

part 'notification_prefs_controller.g.dart';

@riverpod
class NotificationPrefsController extends _$NotificationPrefsController {
  @override
  Future<NotificationPrefs> build() async {
    final repo = ref.read(notificationRepositoryProvider);
    return repo.fetchPrefs();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 단일 토글 PATCH. 호출 측이 optimistic UI를 자체 관리한 후 본 메서드 await.
  /// 성공 시 state 갱신, 실패 시 throw — 호출 측에서 catch → 토글 원복.
  Future<NotificationPrefs> patch(NotificationPrefsPatch patch) async {
    final repo = ref.read(notificationRepositoryProvider);
    final updated = await repo.updatePrefs(patch);
    state = AsyncValue.data(updated);
    return updated;
  }
}
