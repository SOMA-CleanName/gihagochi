/// F-XXX 화면.
///
/// 패턴:
/// - ConsumerWidget으로 controller watch
/// - AsyncValue.when으로 loading/error/data 분기
/// - 공용 위젯 사용 (LoadingView, ErrorView, EmptyView)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/template_controller.dart';

class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(templateControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Template')),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(templateControllerProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(message: '아직 항목이 없습니다.');
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(items[i].title),
              subtitle: Text(items[i].description ?? ''),
            ),
          );
        },
      ),
    );
  }
}
