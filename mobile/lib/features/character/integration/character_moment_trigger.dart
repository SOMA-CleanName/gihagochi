/// F-044 — 캐릭터 모먼트 공개 트리거.
///
/// 다른 피처(gift, chat_message, admin 등)가 캐릭터 위에 모먼트 카드를
/// 띄우고 싶을 때 본 파일의 함수를 import해서 호출.
///
/// 본 PR-4는 인터페이스만 노출. 외부 호출 추가는 후속 PR
/// (chat_message가 gift sheet 닫힘 후 호출 / admin가 운영 트리거 호출).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/character_moment_controller.dart';
import '../domain/character_moment.dart';

export '../domain/character_moment.dart'
    show CharacterMoment, CharacterMomentKind;

/// 일반 모먼트 트리거. 같은 idolId 재호출 시 기존 카드 즉시 dispose + 새 카드.
void triggerCharacterMoment(
  WidgetRef ref, {
  required String idolId,
  required CharacterMomentKind kind,
  String? message,
}) {
  ref
      .read(characterMomentControllerProvider(idolId).notifier)
      .show(kind, message: message);
}

/// 선물 전송 후 호출용 편의 함수.
void triggerGiftMomentForIdol(
  WidgetRef ref,
  String idolId, {
  String? message,
}) {
  triggerCharacterMoment(
    ref,
    idolId: idolId,
    kind: CharacterMomentKind.gift,
    message: message,
  );
}
