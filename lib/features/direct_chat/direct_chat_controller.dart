import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';
import '../../core/viewmodels/task_controller.dart';

class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String code;
  final String dialCode; // e.g. '+84'
  final String flag;

  String get digitsOnly => dialCode.replaceAll('+', '');
}

class DirectChatController extends TaskController {
  DirectChatController(this._platform);
  final AppPlatform _platform;
  final phone = TextEditingController();
  final message = TextEditingController();
  bool business = false;

  CountryDialCode selectedCountry = countries.first;

  static const List<CountryDialCode> countries = [
    CountryDialCode(name: 'Việt Nam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
    CountryDialCode(name: 'Hoa Kỳ (United States)', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryDialCode(name: 'Hàn Quốc (South Korea)', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    CountryDialCode(name: 'Nhật Bản (Japan)', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryDialCode(name: 'Đài Loan (Taiwan)', code: 'TW', dialCode: '+886', flag: '🇹🇼'),
    CountryDialCode(name: 'Trung Quốc (China)', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    CountryDialCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryDialCode(name: 'Thái Lan (Thailand)', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
    CountryDialCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryDialCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    CountryDialCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
    CountryDialCode(name: 'Campuchia (Cambodia)', code: 'KH', dialCode: '+855', flag: '🇰🇭'),
    CountryDialCode(name: 'Lào (Laos)', code: 'LA', dialCode: '+856', flag: '🇱🇦'),
    CountryDialCode(name: 'Úc (Australia)', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryDialCode(name: 'Vương quốc Anh (UK)', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryDialCode(name: 'Pháp (France)', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryDialCode(name: 'Đức (Germany)', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryDialCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryDialCode(name: 'Ấn Độ (India)', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryDialCode(name: 'Nga (Russia)', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
    CountryDialCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryDialCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  ];

  static const List<String> quickTemplates = [
    'Xin chào 👋',
    'Chào bạn, mình có thể trao đổi chút được không?',
    'Vui lòng gọi lại cho mình khi bạn rảnh nhé!',
    'Mình đã nhận được thông tin, cảm ơn bạn!',
    'Bạn gửi giúp mình vị trí hoặc địa chỉ nhé 📍',
    'Cho mình hỏi thông tin chi tiết về sản phẩm này nhé.',
  ];

  String? validatePhone(String? value) {
    final digits = normalize(value ?? '');
    if (!RegExp(r'^[1-9][0-9]{6,14}$').hasMatch(digits)) {
      return 'Nhập mã nước và 7–15 chữ số, ví dụ +84901234567.';
    }
    return null;
  }

  /// Normalizes international phone numbers (`+84 901-234-567` -> `84901234567`).
  /// Also supports local phone numbers starting with `0` (e.g. `0901234567` -> `84901234567`
  /// when at least 9 digits are entered) by prepending `selectedCountry.digitsOnly`.
  String normalize(String raw) {
    final trimmed = raw.trim();
    final digits = trimmed.replaceAll(RegExp(r'[\s()+.-]'), '');
    if (!trimmed.startsWith('+') &&
        digits.startsWith('0') &&
        digits.length >= 9) {
      return '${selectedCountry.digitsOnly}${digits.substring(1)}';
    }
    return digits;
  }

  void applyTemplate(String template) {
    final current = message.text.trim();
    message.text = current.isEmpty ? template : '$current $template';
    message.selection = TextSelection.fromPosition(
      TextPosition(offset: message.text.length),
    );
  }

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
