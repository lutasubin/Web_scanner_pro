import 'package:flutter/foundation.dart';

/// Official Google AdMob Test Ad Unit IDs for Android & iOS.
/// Reference: https://developers.google.com/admob/android/test-ads
class AdTestIds {
  AdTestIds._();

  /// Official Google AdMob Test App ID (declared in AndroidManifest.xml).
  static const String androidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';

  static const String androidAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String iosAppOpenId =
      'ca-app-pub-3940256099942544/5575463023';

  static const String androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String androidAdaptiveBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String iosAdaptiveBannerId =
      'ca-app-pub-3940256099942544/2435281174';

  static const String androidCollapsibleBannerId =
      'ca-app-pub-3940256099942544/2014213617';
  static const String iosCollapsibleBannerId =
      'ca-app-pub-3940256099942544/8388050270';

  static const String androidNativePrimaryId =
      '/21775744923/example/native-video';
  static const String androidNativeFallbackId =
      '/21775744923/example/native';
  static const String androidNativeCollabId =
      '/21775744923/example/native-video';
  static const String androidNativeOnboardingId =
      '/21775744923/example/native-video';
  static const String iosNativePrimaryId =
      '/21775744923/example/native-video';
  static const String iosNativeFallbackId =
      'ca-app-pub-3940256099942544/3986624511';
  static const String iosNativeCollabId =
      '/21775744923/example/native-video';
  static const String iosNativeOnboardingId =
      '/21775744923/example/native-video';

  static String get appOpenAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosAppOpenId
          : androidAppOpenId;

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
