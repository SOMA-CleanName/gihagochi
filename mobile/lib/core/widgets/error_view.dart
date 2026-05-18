/// 에러 화면 — AppError 메시지 표시 + 재시도 버튼.
library;

import 'package:flutter/material.dart';

import '../error/error_handler.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            ErrorHandler.userMessage(error),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppButton(label: '다시 시도', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
