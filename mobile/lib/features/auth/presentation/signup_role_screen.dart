/// F-001/F-002 가입 타입 선택 — 옵션 C.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/signup_controller.dart';
import '../domain/auth_models.dart';

class SignupRoleScreen extends ConsumerWidget {
  const SignupRoleScreen({super.key});

  void _pick(BuildContext context, WidgetRef ref, SignupAs role) {
    ref.read(signupDraftControllerProvider.notifier).setRole(role);
    context.go('/auth/signup/terms');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('어떤 계정으로 시작할까요?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoleCard(
                title: '팬으로 가입',
                description: '아이돌의 채팅방을 응원하고 메시지를 받습니다.',
                onTap: () => _pick(context, ref, SignupAs.fan),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: '아이돌로 가입',
                description: '관리자 승인 후 자기 채팅방에서 팬들에게 메시지를 발행합니다.',
                onTap: () => _pick(context, ref, SignupAs.idol),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}
