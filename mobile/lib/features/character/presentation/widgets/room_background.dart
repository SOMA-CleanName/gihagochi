/// F-039 방 배경 — PNG 에셋 풀스크린.
///
/// 9:19 비율의 픽셀 아트 배경. BoxFit.cover로 화면 전체 채움.
/// 디바이스 비율이 다르면 좌우 또는 상하가 조금 잘림 — 디자인 의도 (중앙 보존).
library;

import 'package:flutter/material.dart';

class RoomBackground extends StatelessWidget {
  const RoomBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/character/room_background.png'),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.none, // 픽셀 아트 — nearest neighbor
    );
  }
}
