import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/di/di.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/router/app_routes.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
}

const kSupportedLanguages = <LanguageOption>[
  LanguageOption(
    code: 'vi',
    nativeName: 'Tiếng Việt',
    englishName: 'Vietnamese',
    flag: '🇻🇳',
  ),
  LanguageOption(
    code: 'en',
    nativeName: 'English',
    englishName: 'English (US)',
    flag: '🇺🇸',
  ),
  LanguageOption(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
    flag: '🇪🇸',
  ),
  LanguageOption(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    flag: '🇵🇹',
  ),
  LanguageOption(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
    flag: '🇫🇷',
  ),
  LanguageOption(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
    flag: '🇩🇪',
  ),
  LanguageOption(
    code: 'id',
    nativeName: 'Indonesia',
    englishName: 'Bahasa Indonesia',
    flag: '🇮🇩',
  ),
  LanguageOption(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    flag: '🇮🇳',
  ),
  LanguageOption(
    code: 'ko',
    nativeName: '한국어',
    englishName: 'Korean',
    flag: '🇰🇷',
  ),
  LanguageOption(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    flag: '🇯🇵',
  ),
];

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late final PreferencesRepository _prefs;
  late String _selectedCode;
  late bool _fromSplash;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefs = services<PreferencesRepository>();
    _selectedCode = _prefs.value.value.languageCode;
    final args = Get.arguments;
    _fromSplash =
        (args is Map && args['fromSplash'] == true) ||
        !_prefs.value.value.onboardingDone;
  }

  Future<void> _confirmSelection() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _prefs.update({
        'languageCode': _selectedCode,
        'onboardingDone': true,
      });
    } catch (_) {}
    if (!mounted) return;
    _applyLocale(_selectedCode);
    if (_fromSplash) {
      await Get.offAllNamed<void>(AppRoutes.home);
    } else {
      Get.back<void>();
    }
  }

  void _selectLanguage(String code) {
    setState(() => _selectedCode = code);
    _applyLocale(code);
  }

  void _applyLocale(String code) {
    Get.locale = Locale(code);
    Get.appUpdate();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F7),
    appBar: AppBar(
      automaticallyImplyLeading: !_fromSplash,
      title: Text(
        'choose_language'.tr,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            key: const Key('confirm-language'),
            onPressed: _saving ? null : _confirmSelection,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF08C567),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text(
              'done'.tr,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            itemCount: kSupportedLanguages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = kSupportedLanguages[index];
              final selected = item.code == _selectedCode;
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: Key('lang-${item.code}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _selectLanguage(item.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF08C567)
                            : const Color(0xFFE3EAE6),
                        width: selected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFE7FAF0)
                                : const Color(0xFFF3F6F4),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            item.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nativeName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: const Color(0xFF1F2A24),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.englishName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF68776F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _LanguageRadioIcon(selected: selected),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _LanguageRadioIcon extends StatelessWidget {
  const _LanguageRadioIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF08C567) : Colors.transparent,
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? const Color(0xFF08C567) : const Color(0xFFC2CEC8),
        width: 2,
      ),
    ),
    child: selected
        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
        : null,
  );
}
