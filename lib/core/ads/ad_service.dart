import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_test_ids.dart';
import 'remote_config_service.dart';

class AdService with WidgetsBindingObserver {
  AdService(this.rc);

  static const _platformChannel = MethodChannel('web_scanner_pro/platform');

  final RemoteConfigService rc;

  final sdkInitialized = false.obs;
  final inSplash = true.obs;
  final isShowingFullScreenAd = false.obs;
  final appOpenCached = false.obs;
  final interstitialCached = false.obs;
  final sharedNativeCachedCount = 0.obs;
  final adEventLogs = <String>[].obs;

  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadTime;
  bool _isLoadingAppOpen = false;
  DateTime? _lastAppOpenDismissTime;
  Completer<bool>? _appOpenLoadCompleter;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterDismissTime;
  Completer<bool>? _interLoadCompleter;

  bool _wasInBackground = false;
  bool _returningFromWebSession = false;
  bool _suppressNextHotOpen = false;

  /// Native Ad Queue Cache (matches `nativeCache = 3` in `bm/e.java` & `yl/e.java`).
  static const int maxNativeCachePerStyle = 3;
  final Map<int, List<NativeAd>> _nativeQueues = <int, List<NativeAd>>{};
  final Map<int, int> _nativeLoadingCount = <int, int>{};
  Worker? _adUnitChangeWorker;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      !Get.testMode;

  int get interCooldownRemainingSec {
    final last = _lastInterDismissTime;
    if (last == null) return 0;
    final elapsed = DateTime.now().difference(last).inSeconds;
    final rem = rc.interIntervalSec.value - elapsed;
    return rem > 0 ? rem : 0;
  }

  int get hotOpenCooldownRemainingSec {
    final last = _lastAppOpenDismissTime;
    if (last == null) return 0;
    final elapsed = DateTime.now().difference(last).inSeconds;
    final rem = rc.hotOpenIntervalSec.value - elapsed;
    return rem > 0 ? rem : 0;
  }

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    if (!isSupportedPlatform) {
      _log('AdService initialized in non-mobile/test mode (no-op SDK).');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      sdkInitialized.value = true;
      _log('Google Mobile Ads SDK initialized (Remote Config Ad Unit IDs).');
      _setupAdUnitChangeListeners();
      preloadAppOpen();
      preloadInterstitial();
      if (defaultTargetPlatform == TargetPlatform.android) {
        unawaited(_preloadAndroidNativeQueue());
      } else {
        // Pre-warm Native Ad queues for active styles on iOS
        final activeStyles = <int>{
          rc.nativeLangStyle.value,
          rc.nativeHomeCollabStyle.value,
          rc.nativeListStyle.value,
          rc.nativeExitStyle.value,
        }..removeWhere((s) => s <= 0);
        for (final style in activeStyles) {
          replenishNativeQueue(style);
        }
      }
    } catch (e) {
      _log('MobileAds init failed: $e');
    }
  }

  void _log(String msg) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    adEventLogs.insert(0, '[$hh:$mm:$ss] $msg');
    if (adEventLogs.length > 60) {
      adEventLogs.removeLast();
    }
  }

  /// Marks that the app has left the Splash screen (`leave_splash` -> `jc.b.e = false` in original app).
  void markLeftSplash() {
    if (inSplash.value) {
      inSplash.value = false;
      _log('Left splash screen -> Hot Start App Open Ads armed.');
    }
  }

  /// Call before launching an external system picker/permission screen so Hot Open Ad won't interrupt.
  void suppressNextHotOpen() {
    _suppressNextHotOpen = true;
  }

  /// Marks that the user is entering `WebSessionActivity` (`jc.b.c = true` in original app).
  void markEnteringWebSession() {
    _returningFromWebSession = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (_returningFromWebSession) {
      _returningFromWebSession = false;
      _log('Resumed from WebSessionActivity -> checking inter_web_back.');
      // Wait 150ms for activity transition to settle before showing interstitial
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await showInterstitial(
        trigger: 'web_back',
        configOn: rc.interWebBack.value,
      );
      return;
    }

    if (_suppressNextHotOpen) {
      _suppressNextHotOpen = false;
      _log('Skipped Hot Start App Open (returning from permission/picker).');
      return;
    }

    if (inSplash.value) return;

    // 100ms delay matching `new Handler(Looper.getMainLooper()).postDelayed(..., 100L)` in `jc/b.java`
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await showHotStartAppOpenAd();
  }

  // ===========================================================================
  // 1. APP OPEN ADS (Cold Start & Hot Start)
  // ===========================================================================

  bool get _isAppOpenValid {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    // AdMob App Open ads expire after 4 hours (`yl/g.java`)
    return DateTime.now().difference(_appOpenLoadTime!) <
        const Duration(hours: 4);
  }

  void _setupAdUnitChangeListeners() {
    _adUnitChangeWorker?.dispose();
    _adUnitChangeWorker = everAll(
      [
        rc.adUnitAppOpenAndroid,
        rc.adUnitAppOpenIos,
        rc.adUnitInterstitialAndroid,
        rc.adUnitInterstitialIos,
        rc.adUnitNativeAndroid,
        rc.adUnitNativeCollabAndroid,
        rc.adUnitNativeFallbackAndroid,
        rc.adUnitNativeIos,
        rc.adUnitNativeCollabIos,
        rc.adUnitNativeFallbackIos,
      ],
      (_) {
        _log('Remote Config Ad Unit IDs updated -> refreshing caches...');
        _appOpenAd?.dispose();
        _appOpenAd = null;
        appOpenCached.value = false;
        _isLoadingAppOpen = false;

        _interstitialAd?.dispose();
        _interstitialAd = null;
        interstitialCached.value = false;
        _isLoadingInterstitial = false;

        for (final list in _nativeQueues.values) {
          for (final ad in list) {
            ad.dispose();
          }
        }
        _nativeQueues.clear();
        _nativeLoadingCount.clear();

        preloadAppOpen();
        preloadInterstitial();
        if (defaultTargetPlatform == TargetPlatform.android) {
          _preloadAndroidNativeQueue();
        } else {
          final activeStyles = <int>{
            rc.nativeLangStyle.value,
            rc.nativeHomeCollabStyle.value,
            rc.nativeListStyle.value,
            rc.nativeExitStyle.value,
          }..removeWhere((s) => s <= 0);
          for (final style in activeStyles) {
            replenishNativeQueue(style);
          }
        }
      },
    );
  }

  void preloadAppOpen() {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    if (_isLoadingAppOpen || _isAppOpenValid) return;
    final adUnitId = rc.activeAppOpenAdUnitId;
    if (adUnitId.isEmpty) {
      _log('AppOpenAd skipped (ad_unit_app_open is empty in Remote Config).');
      return;
    }

    _isLoadingAppOpen = true;
    _appOpenLoadCompleter = Completer<bool>();
    _log('Loading AppOpenAd ($adUnitId)...');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isLoadingAppOpen = false;
          appOpenCached.value = true;
          _log('AppOpenAd loaded and cached (cache=1).');
          if (!(_appOpenLoadCompleter?.isCompleted ?? true)) {
            _appOpenLoadCompleter?.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _isLoadingAppOpen = false;
          appOpenCached.value = false;
          _log('AppOpenAd failed to load: ${error.message}');
          if (!(_appOpenLoadCompleter?.isCompleted ?? true)) {
            _appOpenLoadCompleter?.complete(false);
          }
        },
      ),
    );
  }

  /// Mirrors `showColdStartAd` in `tc/e.java:765-800`:
  /// - `splash_ad_style == 0`: Disabled
  /// - `splash_ad_style == 1`: App Open Ad (with 7000ms load timeout)
  /// - `splash_ad_style == 2`: Interstitial Ad (with 7000ms load timeout)
  Future<void> showColdStartAd({
    Duration timeout = const Duration(milliseconds: 2200),
  }) async {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    final style = rc.splashAdStyle.value;
    if (style <= 0) {
      _log('Cold Start Ad skipped (splash_ad_style = 0).');
      return;
    }

    if (style == 1) {
      // App Open Cold Start
      if (!_isAppOpenValid) {
        preloadAppOpen();
        final completer = _appOpenLoadCompleter;
        if (completer != null) {
          _log('Waiting up to ${timeout.inMilliseconds}ms for Cold Start AppOpenAd...');
          await completer.future.timeout(timeout, onTimeout: () {
            _log('Cold Start AppOpenAd timed out after ${timeout.inMilliseconds}ms.');
            return false;
          });
        }
      }
      if (_isAppOpenValid) {
        await _presentAppOpenAd(trigger: 'cold_start');
      }
    } else if (style == 2) {
      // Interstitial Cold Start
      if (_interstitialAd == null) {
        preloadInterstitial();
        final completer = _interLoadCompleter;
        if (completer != null) {
          _log('Waiting up to ${timeout.inMilliseconds}ms for Cold Start InterstitialAd...');
          await completer.future.timeout(timeout, onTimeout: () {
            _log('Cold Start InterstitialAd timed out after ${timeout.inMilliseconds}ms.');
            return false;
          });
        }
      }
      if (_interstitialAd != null) {
        await showInterstitial(
          trigger: 'cold_start',
          configOn: true,
          ignoreCooldown: true,
        );
      }
    }
  }

  /// Mirrors `xf/b.java:318-341` (`hot_start` App Open Ad on resume).
  Future<bool> showHotStartAppOpenAd({bool ignoreCooldown = false}) async {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return false;
    if (!rc.hotOpenAdEnabled.value) {
      _log('Hot Start AppOpenAd skipped (hot_open_ad_enabled = false).');
      return false;
    }
    if (isShowingFullScreenAd.value) {
      _log('Hot Start AppOpenAd skipped (another full-screen ad is showing).');
      return false;
    }
    if (!ignoreCooldown && hotOpenCooldownRemainingSec > 0) {
      _log('Hot Start AppOpenAd in cooldown (${hotOpenCooldownRemainingSec}s left).');
      return false;
    }
    if (!_isAppOpenValid) {
      _log('Hot Start AppOpenAd cache empty -> preloading for next time.');
      preloadAppOpen();
      return false;
    }
    return _presentAppOpenAd(trigger: 'hot_start');
  }

  Future<bool> _presentAppOpenAd({required String trigger}) async {
    final ad = _appOpenAd;
    if (ad == null || isShowingFullScreenAd.value) return false;

    final dismissCompleter = Completer<bool>();
    _appOpenAd = null;
    appOpenCached.value = false;
    isShowingFullScreenAd.value = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _log('AppOpenAd shown (trigger: $trigger). Replenishing cache...');
        preloadAppOpen();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        isShowingFullScreenAd.value = false;
        _lastAppOpenDismissTime = DateTime.now();
        _log('AppOpenAd dismissed (trigger: $trigger).');
        if (!dismissCompleter.isCompleted) dismissCompleter.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        isShowingFullScreenAd.value = false;
        _log('AppOpenAd failed to show ($trigger): ${error.message}');
        preloadAppOpen();
        if (!dismissCompleter.isCompleted) dismissCompleter.complete(false);
      },
    );

    ad.show();
    return dismissCompleter.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        isShowingFullScreenAd.value = false;
        return false;
      },
    );
  }

  // ===========================================================================
  // 2. INTERSTITIAL ADS (`into` & `back` triggers with `inter_interval_sec`)
  // ===========================================================================

  void preloadInterstitial() {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    final adUnitId = rc.activeInterstitialAdUnitId;
    if (adUnitId.isEmpty) {
      _log('InterstitialAd skipped (ad_unit_interstitial is empty in Remote Config).');
      return;
    }

    _isLoadingInterstitial = true;
    _interLoadCompleter = Completer<bool>();
    _log('Loading InterstitialAd ($adUnitId)...');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          interstitialCached.value = true;
          _log('InterstitialAd loaded and cached (cache=1).');
          if (!(_interLoadCompleter?.isCompleted ?? true)) {
            _interLoadCompleter?.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          interstitialCached.value = false;
          _log('InterstitialAd failed to load: ${error.message}');
          if (!(_interLoadCompleter?.isCompleted ?? true)) {
            _interLoadCompleter?.complete(false);
          }
        },
      ),
    );
  }

  /// Mirrors `xe/f.java` (`showInterstitial(trigger, configOn)`):
  /// Checks `!unShowAd && configOn && cooldown`, shows immediately if cached,
  /// and always executes [onContinue] without blocking the user if not ready.
  Future<bool> showInterstitial({
    required String trigger,
    required bool configOn,
    VoidCallback? onContinue,
    bool ignoreCooldown = false,
  }) async {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value || !configOn) {
      if (!configOn) {
        _log('Interstitial [$trigger] skipped (disabled in Remote Config).');
      }
      onContinue?.call();
      return false;
    }

    if (isShowingFullScreenAd.value) {
      _log('Interstitial [$trigger] skipped (another full-screen ad is showing).');
      onContinue?.call();
      return false;
    }

    if (!ignoreCooldown && interCooldownRemainingSec > 0) {
      _log(
        'Interstitial [$trigger] skipped (cooldown ${interCooldownRemainingSec}s left).',
      );
      onContinue?.call();
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _log('Interstitial [$trigger] cache empty -> continuing & preloading.');
      preloadInterstitial();
      onContinue?.call();
      return false;
    }

    final dismissCompleter = Completer<bool>();
    _interstitialAd = null;
    interstitialCached.value = false;
    isShowingFullScreenAd.value = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _log('Interstitial [$trigger] shown. Replenishing cache...');
        preloadInterstitial();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        isShowingFullScreenAd.value = false;
        _lastInterDismissTime = DateTime.now();
        _log('Interstitial [$trigger] dismissed.');
        onContinue?.call();
        if (!dismissCompleter.isCompleted) dismissCompleter.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        isShowingFullScreenAd.value = false;
        _log('Interstitial [$trigger] failed to show: ${error.message}');
        preloadInterstitial();
        onContinue?.call();
        if (!dismissCompleter.isCompleted) dismissCompleter.complete(false);
      },
    );

    ad.show();
    return dismissCompleter.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        isShowingFullScreenAd.value = false;
        return false;
      },
    );
  }

  // ===========================================================================
  // 3. NATIVE AD QUEUE CACHE (`nativeCache = 3`, styles 1..6)
  // ===========================================================================

  Future<void> _preloadAndroidNativeQueue() async {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    try {
      final count = await _platformChannel.invokeMethod<int>(
        'preloadNativeAds',
        <String, Object?>{
          'adUnitId': rc.activeNativeAdUnitId,
          'fallbackAdUnitId': rc.activeNativeFallbackAdUnitId,
        },
      );
      sharedNativeCachedCount.value = count ?? 0;
      _log(
        'Preloading shared 3-ad Native queue (${rc.activeNativeAdUnitId})...',
      );
      Future<void>.delayed(const Duration(seconds: 2), refreshNativeQueueCount);
      Future<void>.delayed(const Duration(seconds: 4), refreshNativeQueueCount);
    } catch (_) {}
  }

  Future<void> refreshNativeQueueCount() async {
    if (!isSupportedPlatform || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      final count = await _platformChannel.invokeMethod<int>(
        'getNativeCachedCount',
      );
      if (count != null) {
        sharedNativeCachedCount.value = count;
      }
    } catch (_) {}
  }

  int cachedNativeCountForStyle(int style) {
    final s = style.clamp(1, 6);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return sharedNativeCachedCount.value;
    }
    return _nativeQueues[s]?.length ?? 0;
  }

  /// Pops 1 preloaded `NativeAd` from the style queue (0ms delay) and triggers
  /// background replenishment so the queue stays at `maxNativeCachePerStyle = 3`.
  NativeAd? popCachedNativeAd(int style) {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value || style <= 0) {
      return null;
    }
    final s = style.clamp(1, 6);
    final queue = _nativeQueues[s];
    if (queue != null && queue.isNotEmpty) {
      final ad = queue.removeAt(0);
      _log(
        'Popped NativeAd (style=$s) from cache queue (remaining=${queue.length}).',
      );
      replenishNativeQueue(s);
      return ad;
    }
    replenishNativeQueue(s);
    return null;
  }

  void replenishNativeQueue(int style, {bool useVideoTestId = false}) {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value || style <= 0) {
      return;
    }
    final s = style.clamp(1, 6);
    final queue = _nativeQueues.putIfAbsent(s, () => <NativeAd>[]);
    final loading = _nativeLoadingCount[s] ?? 0;
    if (queue.length + loading >= maxNativeCachePerStyle) return;

    _nativeLoadingCount[s] = loading + 1;
    final factoryId = AdTestIds.factoryIdForStyle(s);
    final adUnitId = useVideoTestId
        ? rc.activeNativeFallbackAdUnitId
        : (s == 6 ? rc.activeNativeCollabAdUnitId : rc.activeNativeAdUnitId);
    if (adUnitId.isEmpty) {
      _nativeLoadingCount[s] = loading;
      return;
    }

    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          _nativeLoadingCount[s] = ((_nativeLoadingCount[s] ?? 1) - 1).clamp(
            0,
            maxNativeCachePerStyle,
          );
          if (loadedAd is NativeAd) {
            queue.add(loadedAd);
            _log(
              'NativeAd cached for $factoryId (queue=${queue.length}/$maxNativeCachePerStyle).',
            );
          }
          if (queue.length < maxNativeCachePerStyle) {
            replenishNativeQueue(s, useVideoTestId: useVideoTestId);
          }
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          _nativeLoadingCount[s] = ((_nativeLoadingCount[s] ?? 1) - 1).clamp(
            0,
            maxNativeCachePerStyle,
          );
          _log('NativeAd ($factoryId) failed to load: ${error.message}');
          if (!useVideoTestId) {
            replenishNativeQueue(s, useVideoTestId: true);
          }
        },
      ),
    );
    ad.load();
  }

  void resetCooldowns() {
    _lastInterDismissTime = null;
    _lastAppOpenDismissTime = null;
    _log('Reset Interstitial & Hot Open cooldown timers.');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adUnitChangeWorker?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    for (final list in _nativeQueues.values) {
      for (final ad in list) {
        ad.dispose();
      }
    }
    _nativeQueues.clear();
  }
}
