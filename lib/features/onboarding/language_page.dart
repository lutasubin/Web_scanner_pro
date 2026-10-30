import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_native_ad.dart';
import '../../core/analytics/analytics_service.dart';
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
    englishName: 'English (System Default)',
    flag: '🇺🇸',
  ),
  LanguageOption(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
    flag: '🇩🇪',
  ),
  LanguageOption(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
    flag: '🇪🇸',
  ),
  LanguageOption(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
    flag: '🇫🇷',
  ),
  LanguageOption(
    code: 'id',
    nativeName: 'Bahasa Indonesia',
    englishName: 'Indonesian',
    flag: '🇮🇩',
  ),
  LanguageOption(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    flag: '🇵🇹',
  ),
  LanguageOption(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    flag: '🇯🇵',
  ),
  LanguageOption(
    code: 'ko',
    nativeName: '한국어',
    englishName: 'Korean',
    flag: '🇰🇷',
  ),
  LanguageOption(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    flag: '🇮🇳',
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
    if (services.isRegistered<AnalyticsService>()) {
      services<AnalyticsService>().logEvent('LanguagePage');
    }
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
      await Get.offAllNamed<void>(AppRoutes.onboarding);
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
    backgroundColor: const Color(0xFFF5F6F8),
    appBar: AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: !_fromSplash,
      title: Text(
        'choose_language'.tr,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            key: const Key('confirm-language'),
            onPressed: _saving ? null : _confirmSelection,
            icon: const Icon(
              Icons.check_rounded,
              size: 24,
              color: Color(0xFF1C1F1D),
            ),
            label: Text(
              'done'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1C1F1D),
              ),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE7EAE8)),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                            horizontal: 18,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.nativeName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: selected
                                        ? const Color(0xFF08C567)
                                        : const Color(0xFF1C1F1D),
                                  ),
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
              if (services.isRegistered<RemoteConfigService>())
                AppNativeAd(
                  placement: 'language_page',
                  styleRx: services<RemoteConfigService>().nativeLangStyle,
                ),
            ],
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
        width: 1.8,
      ),
    ),
    child: selected
        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
        : null,
  );
}
