/// F-001~F-006 auth — me 조회 컨트롤러.
///
/// 다른 피처가 watch 가능. role/status에 따라 화면 분기에 사용.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

part 'auth_controller.g.dart';

/// GET /auth/me 결과. profile 없으면 null (404 또는 비로그인).
@riverpod
class AuthController extends _$AuthController {
  @override
  Future<MeResponse?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      return await repo.fetchMe();
    } catch (e) {
      // 401(비로그인) / 404(프로필 미생성) → null. 다른 에러는 propagate.
      return null;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// 공개 인터페이스 — 활성 아이돌 여부. 라우터 가드 / 화면 분기용.
@riverpod
bool isActiveIdol(Ref ref) {
  final me = ref.watch(authControllerProvider).value;
  if (me == null) return false;
  return me.profile.role == UserRole.idol &&
      me.profile.status == UserStatus.active;
}

/// 공개 인터페이스 — 아이돌 신청이 pending 상태인지.
@riverpod
bool hasPendingIdolApplication(Ref ref) {
  final me = ref.watch(authControllerProvider).value;
  final app = me?.latestIdolApplication;
  return app != null && app.status == SignupApplicationStatus.pending;
}
