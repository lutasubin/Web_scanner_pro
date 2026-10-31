import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'ad_test_ids.dart';

/// Manages Firebase Remote Config parameters for all Ad Unit IDs, placements,
/// templates, and cooldown intervals, matching both the original app's keys and
/// granular per-placement switches defined in `remoteconfig.template.json`.
class RemoteConfigService {
  RemoteConfigService();

  FirebaseRemoteConfig? _remoteConfig;
  StreamSubscription<RemoteConfigUpdate>? _configUpdateSub;
  Completer<void>? _initialFetchCompleter;

  final isInitialized = false.obs;
  final lastFetchStatus = 'not_fetched'.obs;
  final lastFetchTime = Rxn<DateTime>();

  // Global & Cooldown Controls
  final adsGlobalEnabled = false.obs;
  final useWaterfallMode = false.obs;
  final splashAdStyle = 1.obs; // 0 = Off, 1 = App Open, 2 = Interstitial
  final hotOpenAdEnabled = true.obs;
  final hotOpenIntervalSec = 10.obs;
  final interIntervalSec = 30.obs;

  // Native Ad Template Styles (0 = Off, 1..5 = XML Template 1..5, 6 = Native Collab)
  // Exact defaults from original app (`frc_..._firebase_defaults.json`):
  // lang_style = 2, list_style = 2, exit_style = 2; Home uses Collapsible Banner (`bannerHomeCollapsible = true`).
  final nativeLangStyle = 2.obs;
  final nativeOnboardingStyle = 5.obs;
  final nativeHomeCollabStyle = 0.obs;
  final nativeListStyle = 2.obs;
  final nativeExitStyle = 2.obs;

  // Interstitial Placement Switches (into / back)
  final interWebInto = true.obs;
  final interWebBack = true.obs;
  final interStatusInto = true.obs;
  final interStatusBack = true.obs;
  final interHistoryInto = true.obs;
  final interHistoryBack = true.obs;
  final interDirectChatInto = true.obs;
  final interDirectChatBack = false.obs;
  final interFilesInto = true.obs;
  final interFilesBack = true.obs;

  // Banner Placement Switches
  final bannerHomeEnabled = true.obs;
  final bannerHomeCollapsible = true.obs;
  final bannerSettingsEnabled = true.obs;
  final bannerSettingsCollapsible = true.obs;
  final bannerWebEnabled = true.obs;
  final bannerStatusEnabled = true.obs;
  final bannerHistoryEnabled = true.obs;
  final bannerFilesEnabled = true.obs;
  final bannerDirectChatEnabled = true.obs;

  // Remote-Configurable Ad Unit IDs (Android & iOS)
  final adUnitAppOpenAndroid = AdTestIds.androidAppOpenId.obs;
  final adUnitAppOpenIos = AdTestIds.iosAppOpenId.obs;
  final adUnitAppOpenResumeAndroid = AdTestIds.androidAppOpenResumeId.obs;
  final adUnitAppOpenResumeIos = AdTestIds.iosAppOpenResumeId.obs;
  final adUnitInterstitialAndroid = AdTestIds.androidInterstitialId.obs;
  final adUnitInterstitialIos = AdTestIds.iosInterstitialId.obs;
  final adUnitBannerAndroid = AdTestIds.androidAdaptiveBannerId.obs;
  final adUnitBannerIos = AdTestIds.iosAdaptiveBannerId.obs;
  final adUnitBannerCollapsibleAndroid = AdTestIds.androidCollapsibleBannerId.obs;
  final adUnitBannerCollapsibleIos = AdTestIds.iosCollapsibleBannerId.obs;
  final adUnitNativeAndroid = AdTestIds.androidNativePrimaryId.obs;
  final adUnitNativeLangAndroid = AdTestIds.androidNativeLangId.obs;
  final adUnitNativeFallbackAndroid = AdTestIds.androidNativeFallbackId.obs;
  final adUnitNativeIos = AdTestIds.iosNativePrimaryId.obs;
  final adUnitNativeLangIos = AdTestIds.iosNativeLangId.obs;
  final adUnitNativeFallbackIos = AdTestIds.iosNativeFallbackId.obs;
  final adUnitNativeCollabAndroid = AdTestIds.androidNativeCollabId.obs;
  final adUnitNativeCollabIos = AdTestIds.iosNativeCollabId.obs;
  final adUnitNativeOnboardingAndroid = AdTestIds.androidNativeOnboardingId.obs;
  final adUnitNativeOnboardingIos = AdTestIds.iosNativeOnboardingId.obs;
  final adUnitRewardAndroid = AdTestIds.androidRewardId.obs;
  final adUnitRewardIos = AdTestIds.iosRewardId.obs;

  String get activeAppOpenAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitAppOpenIos.value
              : adUnitAppOpenAndroid.value)
          .trim();

  String get activeAppOpenResumeAdUnitId {
    final resumeId = (defaultTargetPlatform == TargetPlatform.iOS
            ? adUnitAppOpenResumeIos.value
            : adUnitAppOpenResumeAndroid.value)
        .trim();
    return resumeId.isNotEmpty ? resumeId : activeAppOpenAdUnitId;
  }

  String get activeInterstitialAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitInterstitialIos.value
              : adUnitInterstitialAndroid.value)
          .trim();

  String get activeBannerAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitBannerIos.value
              : adUnitBannerAndroid.value)
          .trim();

  String get activeCollapsibleBannerAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitBannerCollapsibleIos.value
              : adUnitBannerCollapsibleAndroid.value)
          .trim();

  String get activeNativeAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitNativeIos.value
              : adUnitNativeAndroid.value)
          .trim();

  String get activeNativeLangAdUnitId {
    final langId = (defaultTargetPlatform == TargetPlatform.iOS
            ? adUnitNativeLangIos.value
            : adUnitNativeLangAndroid.value)
        .trim();
    return langId.isNotEmpty ? langId : activeNativeAdUnitId;
  }

  String get activeNativeFallbackAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitNativeFallbackIos.value
              : adUnitNativeFallbackAndroid.value)
          .trim();

  String get activeNativeCollabAdUnitId {
    final collabId = (defaultTargetPlatform == TargetPlatform.iOS
            ? adUnitNativeCollabIos.value
            : adUnitNativeCollabAndroid.value)
        .trim();
    return collabId.isNotEmpty ? collabId : activeNativeAdUnitId;
  }

  String get activeNativeOnboardingAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitNativeOnboardingIos.value
              : adUnitNativeOnboardingAndroid.value)
          .trim();

  String get activeRewardAdUnitId =>
      (defaultTargetPlatform == TargetPlatform.iOS
              ? adUnitRewardIos.value
              : adUnitRewardAndroid.value)
          .trim();

  static const Map<String, dynamic> defaultParameters = <String, dynamic>{
    'ads_global_enabled': false,
    'unShowAd': true,
    'wf_mode': false,
    'splash_ad_style': 1,
    'splash_style': 1,
    'hot_open_ad_enabled': true,
    'hot_open_interval_sec': 10,
    'hot_open_interval': 10,
    'inter_interval_sec': 30,
    'inter_interval': 30,
    'native_lang_style': 2,
    'lang_style': 2,
    'native_onboarding_style': 5,
    'onboarding_style': 5,
    'native_home_collab_style': 0,
    'native_list_style': 2,
    'list_style': 2,
    'native_exit_style': 2,
    'exit_style': 2,
    'int_into': true,
    'int_back': true,
    'inter_web_into': true,
    'inter_web_back': true,
    'inter_status_into': true,
    'inter_status_back': true,
    'inter_history_into': true,
    'inter_history_back': true,
    'inter_direct_chat_into': true,
    'inter_direct_chat_back': false,
    'inter_files_into': true,
    'inter_files_back': true,
    'banner_home_enabled': true,
    'banner_home_collapsible': true,
    'banner_settings_enabled': true,
    'banner_settings_collapsible': true,
    'banner_web_enabled': true,
    'banner_status_enabled': true,
    'banner_history_enabled': true,
    'banner_files_enabled': true,
    'banner_direct_chat_enabled': true,
    'ad_unit_app_open_android': AdTestIds.androidAppOpenId,
    'ad_unit_app_open_ios': AdTestIds.iosAppOpenId,
    'ad_unit_app_open_resume_android': AdTestIds.androidAppOpenResumeId,
    'ad_unit_app_open_resume_ios': AdTestIds.iosAppOpenResumeId,
    'ad_unit_interstitial_android': AdTestIds.androidInterstitialId,
    'ad_unit_interstitial_ios': AdTestIds.iosInterstitialId,
    'ad_unit_banner_android': AdTestIds.androidAdaptiveBannerId,
    'ad_unit_banner_ios': AdTestIds.iosAdaptiveBannerId,
    'ad_unit_banner_collapsible_android': AdTestIds.androidCollapsibleBannerId,
    'ad_unit_banner_collapsible_ios': AdTestIds.iosCollapsibleBannerId,
    'ad_unit_native_android': AdTestIds.androidNativePrimaryId,
    'ad_unit_native_lang_android': AdTestIds.androidNativeLangId,
    'ad_unit_native_fallback_android': AdTestIds.androidNativeFallbackId,
    'ad_unit_native_ios': AdTestIds.iosNativePrimaryId,
    'ad_unit_native_lang_ios': AdTestIds.iosNativeLangId,
    'ad_unit_native_fallback_ios': AdTestIds.iosNativeFallbackId,
    'ad_unit_native_collab_android': AdTestIds.androidNativeCollabId,
    'ad_unit_native_collab_ios': AdTestIds.iosNativeCollabId,
    'ad_unit_native_onboarding_android': AdTestIds.androidNativeOnboardingId,
    'ad_unit_native_onboarding_ios': AdTestIds.iosNativeOnboardingId,
    'ad_unit_reward_android': AdTestIds.androidRewardId,
    'ad_unit_reward_ios': AdTestIds.iosRewardId,
  };

  Future<void> init() async {
    _initialFetchCompleter ??= Completer<void>();
    try {
      final rc = FirebaseRemoteConfig.instance;
      _remoteConfig = rc;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(minutes: 15),
        ),
      );
      await rc.setDefaults(defaultParameters);
      _syncFromRemoteConfig(rc);
      isInitialized.value = true;

      // Fetch and activate in background without blocking startup
      unawaited(
        fetchAndActivate().whenComplete(() {
          if (!(_initialFetchCompleter?.isCompleted ?? true)) {
            _initialFetchCompleter?.complete();
          }
        }),
      );

      // Listen for real-time Remote Config pushes from Firebase Console / CLI
      _configUpdateSub?.cancel();
      _configUpdateSub = rc.onConfigUpdated.listen((_) async {
        try {
          await rc.activate();
          _syncFromRemoteConfig(rc);
          lastFetchTime.value = DateTime.now();
          lastFetchStatus.value = 'realtime_updated';
        } catch (_) {}
      });
    } catch (e) {
      // Safe fallback when running in widget tests or offline
      lastFetchStatus.value = 'local_defaults';
      if (!(_initialFetchCompleter?.isCompleted ?? true)) {
        _initialFetchCompleter?.complete();
      }
    }
  }

  /// Waits briefly for the first Firebase Remote Config fetch to complete on cold start.
  Future<void> ensureInitialFetch({
    Duration timeout = const Duration(milliseconds: 2000),
  }) async {
    final completer = _initialFetchCompleter;
    if (completer == null || completer.isCompleted) return;
    await completer.future.timeout(timeout, onTimeout: () {});
  }

  Future<bool> fetchAndActivate() async {
    final rc = _remoteConfig;
    if (rc == null) return false;
    try {
      final updated = await rc.fetchAndActivate();
      _syncFromRemoteConfig(rc);
      lastFetchTime.value = rc.lastFetchTime;
      lastFetchStatus.value = rc.lastFetchStatus.name;
      return updated;
    } catch (_) {
      lastFetchStatus.value = 'fetch_failed_using_cached';
      _syncFromRemoteConfig(rc);
      return false;
    }
  }

  void _syncFromRemoteConfig(FirebaseRemoteConfig rc) {
    final unShowAd = rc.getBool('unShowAd');
    final globalOn = rc.getBool('ads_global_enabled');
    adsGlobalEnabled.value = globalOn && !unShowAd;
    useWaterfallMode.value = rc.getBool('wf_mode');

    splashAdStyle.value = _readStyleOrLegacy(
      rc,
      primaryKey: 'splash_ad_style',
      legacyKey: 'splash_style',
      defaultVal: 1,
      maxStyle: 2,
    );

    hotOpenAdEnabled.value = rc.getBool('hot_open_ad_enabled');
    hotOpenIntervalSec.value = _readPositiveInt(
      rc,
      primaryKey: 'hot_open_interval_sec',
      legacyKey: 'hot_open_interval',
      defaultVal: 10,
    );
    interIntervalSec.value = _readPositiveInt(
      rc,
      primaryKey: 'inter_interval_sec',
      legacyKey: 'inter_interval',
      defaultVal: 30,
    );

    nativeLangStyle.value = _readStyleOrLegacy(
      rc,
      primaryKey: 'native_lang_style',
      legacyKey: 'lang_style',
      defaultVal: 2,
      maxStyle: 6,
    );
    nativeOnboardingStyle.value = _readStyleOrLegacy(
      rc,
      primaryKey: 'native_onboarding_style',
      legacyKey: 'onboarding_style',
      defaultVal: 5,
      maxStyle: 6,
    );
    nativeHomeCollabStyle.value = rc.getInt('native_home_collab_style').clamp(0, 6);
    nativeListStyle.value = _readStyleOrLegacy(
      rc,
      primaryKey: 'native_list_style',
      legacyKey: 'list_style',
      defaultVal: 2,
      maxStyle: 6,
    );
    nativeExitStyle.value = _readStyleOrLegacy(
      rc,
      primaryKey: 'native_exit_style',
      legacyKey: 'exit_style',
      defaultVal: 2,
      maxStyle: 6,
    );

    final masterInto = rc.getBool('int_into');
    final masterBack = rc.getBool('int_back');

    interWebInto.value = masterInto && rc.getBool('inter_web_into');
    interWebBack.value = masterBack && rc.getBool('inter_web_back');
    interStatusInto.value = masterInto && rc.getBool('inter_status_into');
    interStatusBack.value = masterBack && rc.getBool('inter_status_back');
    interHistoryInto.value = masterInto && rc.getBool('inter_history_into');
    interHistoryBack.value = masterBack && rc.getBool('inter_history_back');
    interDirectChatInto.value =
        masterInto && rc.getBool('inter_direct_chat_into');
    interDirectChatBack.value =
        masterBack && rc.getBool('inter_direct_chat_back');
    interFilesInto.value = masterInto && rc.getBool('inter_files_into');
    interFilesBack.value = masterBack && rc.getBool('inter_files_back');

    bannerHomeEnabled.value = rc.getBool('banner_home_enabled');
    bannerHomeCollapsible.value = rc.getBool('banner_home_collapsible');
    bannerSettingsEnabled.value = rc.getBool('banner_settings_enabled');
    bannerSettingsCollapsible.value = rc.getBool('banner_settings_collapsible');
    bannerWebEnabled.value = rc.getBool('banner_web_enabled');
    bannerStatusEnabled.value = rc.getBool('banner_status_enabled');
    bannerHistoryEnabled.value = rc.getBool('banner_history_enabled');
    bannerFilesEnabled.value = rc.getBool('banner_files_enabled');
    bannerDirectChatEnabled.value = rc.getBool('banner_direct_chat_enabled');

    adUnitAppOpenAndroid.value = rc.getString('ad_unit_app_open_android').trim();
    adUnitAppOpenIos.value = rc.getString('ad_unit_app_open_ios').trim();
    adUnitAppOpenResumeAndroid.value =
        rc.getString('ad_unit_app_open_resume_android').trim();
    adUnitAppOpenResumeIos.value =
        rc.getString('ad_unit_app_open_resume_ios').trim();
    adUnitInterstitialAndroid.value =
        rc.getString('ad_unit_interstitial_android').trim();
    adUnitInterstitialIos.value =
        rc.getString('ad_unit_interstitial_ios').trim();
    adUnitBannerAndroid.value = rc.getString('ad_unit_banner_android').trim();
    adUnitBannerIos.value = rc.getString('ad_unit_banner_ios').trim();
    adUnitBannerCollapsibleAndroid.value =
        rc.getString('ad_unit_banner_collapsible_android').trim();
    adUnitBannerCollapsibleIos.value =
        rc.getString('ad_unit_banner_collapsible_ios').trim();
    adUnitNativeAndroid.value = rc.getString('ad_unit_native_android').trim();
    adUnitNativeLangAndroid.value =
        rc.getString('ad_unit_native_lang_android').trim();
    adUnitNativeFallbackAndroid.value =
        rc.getString('ad_unit_native_fallback_android').trim();
    adUnitNativeIos.value = rc.getString('ad_unit_native_ios').trim();
    adUnitNativeLangIos.value =
        rc.getString('ad_unit_native_lang_ios').trim();
    adUnitNativeFallbackIos.value =
        rc.getString('ad_unit_native_fallback_ios').trim();
    adUnitNativeCollabAndroid.value =
        rc.getString('ad_unit_native_collab_android').trim();
    adUnitNativeCollabIos.value =
        rc.getString('ad_unit_native_collab_ios').trim();
    adUnitNativeOnboardingAndroid.value =
        rc.getString('ad_unit_native_onboarding_android').trim();
    adUnitNativeOnboardingIos.value =
        rc.getString('ad_unit_native_onboarding_ios').trim();
    adUnitRewardAndroid.value = rc.getString('ad_unit_reward_android').trim();
    adUnitRewardIos.value = rc.getString('ad_unit_reward_ios').trim();
  }

  int _readStyleOrLegacy(
    FirebaseRemoteConfig rc, {
    required String primaryKey,
    required String legacyKey,
    required int defaultVal,
    required int maxStyle,
  }) {
    final primaryVal = rc.getInt(primaryKey);
    final legacyVal = rc.getInt(legacyKey);
    final chosen = primaryVal != defaultVal ? primaryVal : legacyVal;
    return chosen.clamp(0, maxStyle);
  }

  int _readPositiveInt(
    FirebaseRemoteConfig rc, {
    required String primaryKey,
    required String legacyKey,
    required int defaultVal,
  }) {
    final primaryVal = rc.getInt(primaryKey);
    final legacyVal = rc.getInt(legacyKey);
    final chosen = primaryVal != defaultVal ? primaryVal : legacyVal;
    return chosen < 0 ? 0 : chosen;
  }

  void dispose() {
    _configUpdateSub?.cancel();
  }
}
