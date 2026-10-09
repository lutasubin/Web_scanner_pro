import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../constants/app_copy.dart';

class TaskController extends GetxController {
  final busy = false.obs;
  final error = ''.obs;
  final notice = ''.obs;

  Future<bool> perform(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (busy.value) return false;
    busy.value = true;
    error.value = '';
    notice.value = '';
    try {
      await action();
      if (success != null) notice.value = success;
      return true;
    } on PlatformException catch (exception) {
      error.value = exception.message ?? AppCopy.genericError;
    } on MissingPluginException {
      error.value = 'Tính năng này cần chạy trên ứng dụng Android.';
    } catch (_) {
      error.value = AppCopy.genericError;
    } finally {
      busy.value = false;
    }
    return false;
  }
}
