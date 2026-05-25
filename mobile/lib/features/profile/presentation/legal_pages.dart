/// F-034 — 약관 / 개인정보 / 고객센터.
///
/// 1차는 hardcoded placeholder 텍스트.
/// 출시 전 메인 빌더가 실제 문안으로 교체.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TosPage extends StatelessWidget {
  const TosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: '이용약관',
      body: '''(이용약관 placeholder)

기하고치 서비스의 이용약관입니다. 정식 문안은 출시 전 안내됩니다.

1. 본 약관은 기하고치(이하 "서비스")가 제공하는 모든 서비스 이용 조건을 정합니다.
2. 사용자는 본 약관에 동의함으로써 서비스를 이용할 수 있습니다.
3. 자세한 내용은 추후 안내됩니다.
''',
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: '개인정보 처리방침',
      body: '''(개인정보 처리방침 placeholder)

기하고치는 회원님의 개인정보를 안전하게 보호합니다. 정식 처리방침은 출시 전 안내됩니다.

1. 수집 항목: 이메일, 프로필 사진, 닉네임 등
2. 이용 목적: 서비스 제공 및 운영
3. 보관 기간: 회원 탈퇴 후 30일
''',
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const _supportEmail = 'support@gihagochi.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고객센터')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '문의는 아래 이메일로 보내주세요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    _supportEmail,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '복사',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _supportEmail),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이메일 주소를 복사했습니다.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalScaffold extends StatelessWidget {
  const _LegalScaffold({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
