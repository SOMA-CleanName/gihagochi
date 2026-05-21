/// F-001 가입 흐름 상태.
///
/// 옵션 C 단계:
///   landing → role 선택 → 약관 동의 → OAuth → display_name 입력 → POST /auth/signup
///
/// 화면 간 입력값을 ref-watched 상태로 유지 (사용자 뒤로 가기 등 복원).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import 'auth_controller.dart';

part 'signup_controller.freezed.dart';
part 'signup_controller.g.dart';

@freezed
abstract class SignupDraft with _$SignupDraft {
  const factory SignupDraft({
    SignupAs? signupAs,
    @Default(false) bool tosAgreed,
    @Default(false) bool privacyAgreed,
    @Default(false) bool marketingAgreed,
    String? displayName,
    String? stageName,
    String? bio,
  }) = _SignupDraft;
}

/// 화면 간 공유되는 가입 입력값. 화면 build에서 ref.watch.
@Riverpod(keepAlive: true)
class SignupDraftController extends _$SignupDraftController {
  @override
  SignupDraft build() => const SignupDraft();

  void setRole(SignupAs role) => state = state.copyWith(signupAs: role);

  void setTos(bool v) => state = state.copyWith(tosAgreed: v);
  void setPrivacy(bool v) => state = state.copyWith(privacyAgreed: v);
  void setMarketing(bool v) => state = state.copyWith(marketingAgreed: v);

  void setProfile({
    required String displayName,
    String? stageName,
    String? bio,
  }) =>
      state = state.copyWith(
        displayName: displayName,
        stageName: stageName,
        bio: bio,
      );

  void reset() => state = const SignupDraft();
}

/// 가입 제출 액션 + AsyncValue로 진행/에러 상태 노출.
@riverpod
class SignupSubmitter extends _$SignupSubmitter {
  @override
  AsyncValue<SignupResponse?> build() => const AsyncValue.data(null);

  /// 현재 draft + 약관 version으로 POST /auth/signup 호출.
  /// 성공 시 auth_controller 갱신해서 redirect가 분기되도록.
  Future<void> submit() async {
    final draft = ref.read(signupDraftControllerProvider);
    final repo = ref.read(authRepositoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 1) 현재 약관 version 조회 (서버 신뢰).
      final terms = await repo.fetchCurrentTerms();

      // 2) draft → SignupRequest 매핑.
      final req = SignupRequest(
        signupAs: draft.signupAs ?? SignupAs.fan,
        displayName: (draft.displayName ?? '').trim(),
        stageName: draft.signupAs == SignupAs.idol
            ? (draft.stageName ?? '').trim()
            : null,
        bio: draft.bio,
        agreements: AgreementsInput(
          tos: AgreementInput(version: terms.tos, agreed: draft.tosAgreed),
          privacy: AgreementInput(
            version: terms.privacy,
            agreed: draft.privacyAgreed,
          ),
          marketing: AgreementInput(
            version: terms.marketing,
            agreed: draft.marketingAgreed,
          ),
        ),
      );

      final res = await repo.signup(req);

      // 3) auth_controller가 새 프로필을 인식하도록 refresh.
      await ref.read(authControllerProvider.notifier).refresh();

      // 4) draft 비움 (다음 가입 시도에 영향 X).
      ref.read(signupDraftControllerProvider.notifier).reset();

      return res;
    });
  }
}
