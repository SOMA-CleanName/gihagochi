/// F-XXX controller — UI state + 사용자 액션.
///
/// AsyncNotifier 패턴: AsyncValue<T>로 loading/error/data 자동 매핑.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/template_repository.dart';
import '../domain/template_model.dart';

part 'template_controller.g.dart';

@riverpod
class TemplateController extends _$TemplateController {
  @override
  Future<List<TemplateItem>> build() async {
    final repo = ref.watch(templateRepositoryProvider);
    return repo.fetchAll();
  }

  Future<void> create(String title) async {
    final repo = ref.read(templateRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.create(title: title);
      return repo.fetchAll();
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
