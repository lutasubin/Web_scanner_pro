import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';
import '../../core/viewmodels/task_controller.dart';

class DirectChatController extends TaskController {
  DirectChatController(this._platform);
  final AppPlatform _platform;
  final phone = TextEditingController();
  final message = TextEditingController();
  bool business = false;

  String? validatePhone(String? value) {
    final digits = normalize(value ?? '');
    if (!RegExp(r'^[1-9][0-9]{6,14}$').hasMatch(digits)) {
      return 'Nhập mã nước và 7–15 chữ số, ví dụ +84901234567.';
    }
    return null;
  }

  String normalize(String raw) => raw.replaceAll(RegExp(r'[\s()+.-]'), '');
  Future<void> launch() => perform(
    () => _platform.invoke<void>('openDirectChat', {
      'phone': normalize(phone.text),
      'message': message.text,
      'business': business,
    }),
  );
  @override
  void onClose() {
    phone.dispose();
    message.dispose();
    super.onClose();
  }
}
