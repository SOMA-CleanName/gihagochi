/// 표준 텍스트 입력. label + 에러 표시.
library;

import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    );
  }
}
