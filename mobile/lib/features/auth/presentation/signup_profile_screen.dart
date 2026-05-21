/// F-001/F-002 display_name (+ 아이돌은 stage_name) 입력 + POST /auth/signup.
///
/// 진입 조건: OAuth 통과(currentUser != null) + profile 미존재.
/// 라우터 redirect가 다음 cold-start 시 분기.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../application/signup_controller.dart';
import '../domain/auth_models.dart';

class SignupProfileScreen extends ConsumerStatefulWidget {
  const SignupProfileScreen({super.key});

  @override
  ConsumerState<SignupProfileScreen> createState() =>
      _SignupProfileScreenState();
}

class _SignupProfileScreenState extends ConsumerState<SignupProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _stageNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _stageNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool get _isIdol =>
      ref.read(signupDraftControllerProvider).signupAs == SignupAs.idol;

  Future<void> _submit() async {
    final notifier = ref.read(signupDraftControllerProvider.notifier);
    notifier.setProfile(
      displayName: _displayNameCtrl.text,
      stageName: _isIdol ? _stageNameCtrl.text : null,
      bio: _isIdol ? _bioCtrl.text : null,
    );
    await ref.read(signupSubmitterProvider.notifier).submit();

    final result = ref.read(signupSubmitterProvider);
    if (!mounted) return;
    result.when(
      data: (res) {
        if (res == null) return;
        // 가입 직후 분기: 아이돌이면 승인 대기로, 아니면 홈으로.
        if (res.idolApplication != null) {
          context.go('/auth/idol-pending');
        } else {
          context.go('/');
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitter = ref.watch(signupSubmitterProvider);
    final isIdol = _isIdol;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 입력')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            children: [
              AppTextField(
                controller: _displayNameCtrl,
                label: '닉네임 (1~30자) *',
              ),
              if (isIdol) ...[
                const SizedBox(height: 16),
                AppTextField(
                  controller: _stageNameCtrl,
                  label: '활동명 *',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _bioCtrl,
                  label: '소개 (선택) — 관리자 심사 시 참고',
                  maxLines: 4,
                ),
              ],
              const SizedBox(height: 24),
              if (submitter.hasError) ...[
                Text(
                  '가입 실패: ${submitter.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],
              AppButton(
                label: '완료',
                onPressed: submitter.isLoading ? null : _submit,
                isLoading: submitter.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
