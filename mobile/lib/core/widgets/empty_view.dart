/// 빈 상태 — 데이터 없을 때.
library;

import 'package:flutter/material.dart';

import '../theme/text_styles.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.emptyHint),
        ],
      ),
    );
  }
}
