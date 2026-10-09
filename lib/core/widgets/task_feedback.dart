import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../viewmodels/task_controller.dart';

class TaskFeedback extends StatelessWidget {
  const TaskFeedback({super.key, required this.controller, this.onRetry});
  final TaskController controller;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Obx(() {
    final error = controller.error.value;
    final notice = controller.notice.value;
    if (controller.busy.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(semanticsLabel: 'Đang xử lý'),
      );
    }
    if (error.isEmpty && notice.isEmpty) return const SizedBox(height: 16);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: error.isEmpty
                ? scheme.primaryContainer
                : scheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error.isEmpty ? notice : error,
                style: TextStyle(
                  color: error.isEmpty
                      ? scheme.onPrimaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
              if (error.isNotEmpty && onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  });
}
