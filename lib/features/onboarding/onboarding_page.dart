import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_native_ad.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/router/app_routes.dart';

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.imageAsset,
    required this.titleKey,
  });

  final String imageAsset;
  final String titleKey;
}

const _kOnboardingSteps = <_OnboardingStepData>[
  _OnboardingStepData(
    imageAsset: 'assets/images/img_onboading1.png',
    titleKey: 'onboarding_title_1',
  ),
  _OnboardingStepData(
    imageAsset: 'assets/images/img_onboadring2.png',
    titleKey: 'onboarding_title_2',
  ),
  _OnboardingStepData(
    imageAsset: 'assets/images/img_onboading3.png',
    titleKey: 'onboarding_title_3',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _kPrimaryGreen = Color(0xFF0FBC5D);

  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    if (services.isRegistered<AnalyticsService>()) {
      services<AnalyticsService>().logEvent('OnboardingPage');
    }
    if (services.isRegistered<AdService>()) {
      services<AdService>().preloadOnboardingNativeAd();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < _kOnboardingSteps.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    if (services.isRegistered<PreferencesRepository>()) {
      try {
        await services<PreferencesRepository>().update({
          'onboardingDone': true,
        });
      } catch (_) {}
    }
    if (!mounted) return;
    await Get.offAllNamed<void>(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentIndex == _kOnboardingSteps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        bottom: !isLastStep,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _kOnboardingSteps.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final step = _kOnboardingSteps[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
                        child: Column(
                          children: [
                            const Spacer(flex: 1),
                            Expanded(
                              flex: 11,
                              child: Center(
                                child: Image.asset(
                                  step.imageAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              step.titleKey.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                                color: Color(0xFF111111),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (!isLastStep)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        key: Key('onboarding-next-${_currentIndex + 1}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _goNext,
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  _buildLastStepBottomSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastStepBottomSection(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 18, bottom: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('onboarding-start'),
              onPressed: _finishing ? null : _finishOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: _kPrimaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kPrimaryGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
        if (services.isRegistered<RemoteConfigService>())
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFAF6F5),
              border: Border(
                top: BorderSide(color: Color(0xFFECE8E6), width: 1),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: AppNativeAd(
              placement: 'onboarding_page',
              styleRx: services<RemoteConfigService>().nativeOnboardingStyle,
            ),
          )
        else
          SizedBox(height: bottomInset + 16),
      ],
    );
  }
}
