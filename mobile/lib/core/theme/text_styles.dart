/// 텍스트 스타일 토큰. ThemeData.textTheme 위에 보조 스타일.
library;

import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // 채팅 메시지 본문
  static const messageBody = TextStyle(fontSize: 15, height: 1.4);

  // 채팅 타임스탬프
  static const messageTimestamp = TextStyle(
    fontSize: 11,
    color: Color(0xFF888888),
  );

  // 빈 상태 안내
  static const emptyHint = TextStyle(fontSize: 14, color: Color(0xFF888888));
}
