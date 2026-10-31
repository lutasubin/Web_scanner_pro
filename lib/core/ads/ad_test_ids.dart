import 'package:flutter/foundation.dart';

/// Production & Default AdMob Ad Unit IDs for WA Web Scanner - Dual App.
class AdTestIds {
  AdTestIds._();

  /// Official AdMob App ID (declared in AndroidManifest.xml).
  static const String androidTestAppId =
      'ca-app-pub-8885343988640187~3074190120';

  /// Open ads (Splash / Cold Start)
  static const String androidAppOpenId =
      'ca-app-pub-8885343988640187/2738314056';
  static const String iosAppOpenId =
      'ca-app-pub-8885343988640187/2738314056';

  /// Open resume (Hot Start / App Resume)
  static const String androidAppOpenResumeId =
      'ca-app-pub-8885343988640187/6717921661';
  static const String iosAppOpenResumeId =
      'ca-app-pub-8885343988640187/6717921661';

  /// Inter (Interstitial)
  static const String androidInterstitialId =
      'ca-app-pub-8885343988640187/9344085000';
  static const String iosInterstitialId =
      'ca-app-pub-8885343988640187/9344085000';

  /// Banner (Adaptive & Collapsible)
  static const String androidAdaptiveBannerId =
      'ca-app-pub-8885343988640187/1657166677';
  static const String iosAdaptiveBannerId =
      'ca-app-pub-8885343988640187/1657166677';

  static const String androidCollapsibleBannerId =
      'ca-app-pub-8885343988640187/1657166677';
  static const String iosCollapsibleBannerId =
      'ca-app-pub-8885343988640187/1657166677';

  /// Native (General Native: List, Exit Dialog, Onboarding, Collab)
  static const String androidNativePrimaryId =
      'ca-app-pub-8885343988640187/3434328958';
  static const String androidNativeFallbackId =
      'ca-app-pub-8885343988640187/5042924095';
  static const String androidNativeLangId =
      'ca-app-pub-8885343988640187/5042924095';
  static const String androidNativeCollabId =
      'ca-app-pub-8885343988640187/3434328958';
  static const String androidNativeOnboardingId =
      'ca-app-pub-8885343988640187/3434328958';

  static const String iosNativePrimaryId =
      'ca-app-pub-8885343988640187/3434328958';
  static const String iosNativeFallbackId =
      'ca-app-pub-8885343988640187/5042924095';
  static const String iosNativeLangId =
      'ca-app-pub-8885343988640187/5042924095';
  static const String iosNativeCollabId =
      'ca-app-pub-8885343988640187/3434328958';
  static const String iosNativeOnboardingId =
      'ca-app-pub-8885343988640187/3434328958';

  /// Reward
  static const String androidRewardId =
      'ca-app-pub-8885343988640187/1826180926';
  static const String iosRewardId =
      'ca-app-pub-8885343988640187/1826180926';

  static String get appOpenAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosAppOpenId
          : androidAppOpenId;

  static String get appOpenResumeAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosAppOpenResumeId
          : androidAppOpenResumeId;

  static String get interstitialAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosInterstitialId
          : androidInterstitialId;

  static String get adaptiveBannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosAdaptiveBannerId
          : androidAdaptiveBannerId;

  static String get collapsibleBannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosCollapsibleBannerId
          : androidCollapsibleBannerId;

  static String get nativeAdvancedAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosNativePrimaryId
          : androidNativePrimaryId;

  static String get nativeVideoAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosNativeFallbackId
          : androidNativeFallbackId;

  /// Maps Native Ad style (1..6) to the registered Android NativeAdFactory ID
  /// in `WebScannerNativeAdFactory.kt` (1..5 from `jc/a.java` + 6 = Native Collab).
  static String factoryIdForStyle(int style) {
    final clamped = style.clamp(1, 6);
    return 'adFactoryStyle$clamped';
  }
}
