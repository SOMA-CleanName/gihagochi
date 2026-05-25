/// F-011 idol_discovery — 상세 controller. idolId family.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/idol_repository.dart';
import '../domain/idol_models.dart';

part 'idol_detail_controller.g.dart';

@riverpod
class IdolDetailController extends _$IdolDetailController {
  @override
  Future<IdolDetail> build(String idolId) async {
    final repo = ref.read(idolRepositoryProvider);
    return repo.fetchDetail(idolId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
