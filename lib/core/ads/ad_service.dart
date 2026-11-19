import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_service.dart';
import '../di/di.dart';
import 'ad_test_ids.dart';
import 'remote_config_service.dart';

class AdService with WidgetsBindingObserver {
  AdService(this.rc);

  static const _platformChannel = MethodChannel('web_scanner_pro/platform');

  final RemoteConfigService rc;

  final sdkInitialized = false.obs;
  final Completer<void> _sdkInitCompleter = Completer<void>();
  final inSplash = true.obs;
  final isShowingFullScreenAd = false.obs;
  final appOpenCached = false.obs;
  final interstitialCached = false.obs;
  final sharedNativeCachedCount = 0.obs;
  final adEventLogs = <String>[].obs;

  AppOpenAd? _appOpenAd;
  String? _loadedAppOpenUnitId;
  DateTime? _appOpenLoadTime;
  bool _isLoadingAppOpen = false;
  int _appOpenLoadGen = 0;
  DateTime? _lastAppOpenDismissTime;
  Completer<bool>? _appOpenLoadCompleter;

  InterstitialAd? _interstitialAd;
  String? _loadedInterUnitId;
  bool _isLoadingInterstitial = false;
  int _interLoadGen = 0;
  DateTime? _lastInterDismissTime;
  Completer<bool>? _interLoadCompleter;
  Timer? _interReplenishTimer;

  bool _wasInBackground = false;
  bool _returningFromWebSession = false;
  bool _suppressNextHotOpen = false;
  bool _hasEnteredHome = false;

  /// Just-In-Time Native Ad Cache (max 1 ad to avoid wasting unmatched/unshown preloads).
  static const int maxNativeCachePerStyle = 1;
  final Map<int, List<NativeAd>> _nativeQueues = <int, List<NativeAd>>{};
  final Map<int, int> _nativeLoadingCount = <int, int>{};
  Worker? _configRevisionWorker;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      !Get.testMode;

  @visibleForTesting
  bool get hasPendingInterReplenishTimer =>
      _interReplenishTimer?.isActive ?? false;

  @visibleForTesting
  bool get hasEnteredHome => _hasEnteredHome;

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

  Future<void> ensureInitialized({
    Duration timeout = const Duration(milliseconds: 3500),
  }) async {
    if (!isSupportedPlatform || _sdkInitCompleter.isCompleted) return;
    await _sdkInitCompleter.future.timeout(timeout, onTimeout: () {});
  }

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    if (!isSupportedPlatform) {
      _log('AdService initialized in non-mobile/test mode (no-op SDK).');
      if (!_sdkInitCompleter.isCompleted) _sdkInitCompleter.complete();
      return;
    }
    try {
      await MobileAds.instance.initialize();
      sdkInitialized.value = true;
      _log('Google Mobile Ads SDK initialized (JIT Show-Rate Optimized).');
      _setupConfigRevisionListener();
      // Only preload the immediate Cold Start ad on launch.
      // Interstitials preload once the user reaches Home; Open Resume preloads
      // on app background; Native ads preload just-in-time per screen.
      if (inSplash.value) {
        if (rc.splashAdStyle.value == 1) {
          preloadAppOpen(forResume: false);
        } else if (rc.splashAdStyle.value == 2) {
          preloadInterstitial();
        }
      }
    } catch (e) {
      _log('MobileAds init failed: $e');
    } finally {
      if (!_sdkInitCompleter.isCompleted) _sdkInitCompleter.complete();
    }
  }

  void _log(String msg) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final entry = '[$hh:$mm:$ss] $msg';
    if (kDebugMode) {
      debugPrint('[AdService] $entry');
    }
    adEventLogs.insert(0, entry);
    if (adEventLogs.length > 60) {
      adEventLogs.removeLast();
    }
  }

  /// Marks that the app has left the Splash screen (`leave_splash`).
  void markLeftSplash() {
    if (inSplash.value) {
      inSplash.value = false;
      _log('Left splash screen -> Hot Start App Open Ads armed.');
    }
  }

  /// Called when the user reaches `HomePage` so Interstitial preloading begins
  /// only for active sessions that actually enter feature navigation.
  void onEnteredHome() {
    _hasEnteredHome = true;
    _scheduleInterstitialReplenish();
  }

  /// Call before launching an external system picker/permission screen so Hot Open Ad won't interrupt.
  void suppressNextHotOpen() {
    _suppressNextHotOpen = true;
  }

  /// Marks that the user is entering `WebSessionActivity`.
  void markEnteringWebSession() {
    _returningFromWebSession = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_wasInBackground) {
        _wasInBackground = true;
        _onAppPaused();
      }
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _onAppResumed();
    }
  }

  void _onAppPaused() {
    // Never preload an Interstitial while the user has backgrounded the app.
    _cancelInterReplenishTimer();

    // Just-in-time preload for Hot Start (`Open resume`) only when the user
    // actually backgrounds the app after leaving Splash.
    if (!inSplash.value &&
        rc.adsGlobalEnabled.value &&
        rc.hotOpenAdEnabled.value &&
        !_suppressNextHotOpen &&
        !_returningFromWebSession &&
        !isShowingFullScreenAd.value &&
        hotOpenCooldownRemainingSec == 0 &&
        !_isAppOpenValid &&
        !_isLoadingAppOpen) {
      preloadAppOpen(forResume: true);
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
      _scheduleInterstitialReplenish();
      return;
    }

    if (_suppressNextHotOpen) {
      _suppressNextHotOpen = false;
      _log('Skipped Hot Start App Open (returning from permission/picker).');
      _scheduleInterstitialReplenish();
      return;
    }

    if (inSplash.value) return;

    // 100ms delay for activity resume to settle
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await showHotStartAppOpenAd();
    _scheduleInterstitialReplenish();
  }

  // ===========================================================================
  // 1. REMOTE CONFIG SINGLE-SIGNAL SYNC (No Reload Storm)
  // ===========================================================================

  void _setupConfigRevisionListener() {
    _configRevisionWorker?.dispose();
    _configRevisionWorker = ever<int>(rc.configRevision, (_) {
      _onRemoteConfigUpdated();
    });
  }

  void _onRemoteConfigUpdated() {
    if (!rc.adsGlobalEnabled.value) {
      _log('Remote Config disabled ads -> clearing cached ads & timers.');
      _cancelInterReplenishTimer();
      _disposeAppOpenCache(bumpGen: true);
      _disposeInterstitialCache(bumpGen: true);
      _disposeAllNativeQueues();
      return;
    }

    // 1) App Open: only invalidate if the cached ad's unit ID is no longer valid.
    final coldUnit = rc.activeAppOpenAdUnitId;
    final resumeUnit = rc.activeAppOpenResumeAdUnitId;
    if (_appOpenAd != null &&
        _loadedAppOpenUnitId != coldUnit &&
        _loadedAppOpenUnitId != resumeUnit) {
      _log('AppOpen Ad Unit ID changed -> invalidating cached AppOpenAd.');
      _disposeAppOpenCache(bumpGen: true);
    }
    if (inSplash.value &&
        rc.splashAdStyle.value == 1 &&
        !_isAppOpenValid &&
        !_isLoadingAppOpen) {
      preloadAppOpen(forResume: false);
    }

    // 2) Interstitial: only invalidate if the Interstitial unit ID changed.
    final interUnit = rc.activeInterstitialAdUnitId;
    if (_interstitialAd != null && _loadedInterUnitId != interUnit) {
      _log('Interstitial Ad Unit ID changed -> invalidating cached InterstitialAd.');
      _disposeInterstitialCache(bumpGen: true);
    }
    if (inSplash.value &&
        rc.splashAdStyle.value == 2 &&
        _interstitialAd == null &&
        !_isLoadingInterstitial) {
      preloadInterstitial();
    } else if (_hasEnteredHome) {
      _scheduleInterstitialReplenish();
    }
  }

  void _disposeAppOpenCache({required bool bumpGen}) {
    if (bumpGen) {
      _appOpenLoadGen++;
      _isLoadingAppOpen = false;
      if (!(_appOpenLoadCompleter?.isCompleted ?? true)) {
        _appOpenLoadCompleter?.complete(false);
      }
    }
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadedAppOpenUnitId = null;
    _appOpenLoadTime = null;
    appOpenCached.value = false;
  }

  void _disposeInterstitialCache({required bool bumpGen}) {
    if (bumpGen) {
      _interLoadGen++;
      _isLoadingInterstitial = false;
      if (!(_interLoadCompleter?.isCompleted ?? true)) {
        _interLoadCompleter?.complete(false);
      }
    }
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _loadedInterUnitId = null;
    interstitialCached.value = false;
  }

  void _disposeAllNativeQueues() {
    for (final list in _nativeQueues.values) {
      for (final ad in list) {
        ad.dispose();
      }
    }
    _nativeQueues.clear();
    _nativeLoadingCount.clear();
  }

  // ===========================================================================
  // 2. APP OPEN ADS (Cold Start & Hot Start)
  // ===========================================================================

  bool get _isAppOpenValid {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    // AdMob App Open ads expire after 4 hours.
    return DateTime.now().difference(_appOpenLoadTime!) <
        const Duration(hours: 4);
  }

  void preloadAppOpen({bool forResume = false}) {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    if (_isLoadingAppOpen || _isAppOpenValid) return;
    final adUnitId = (forResume || !inSplash.value)
        ? rc.activeAppOpenResumeAdUnitId
        : rc.activeAppOpenAdUnitId;
    if (adUnitId.isEmpty) {
      _log('AppOpenAd skipped (ad_unit_app_open is empty in Remote Config).');
      return;
    }

    _isLoadingAppOpen = true;
    final gen = ++_appOpenLoadGen;
    _appOpenLoadCompleter = Completer<bool>();
    _log('Loading AppOpenAd (${forResume ? "resume" : "cold"}: $adUnitId)...');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (gen != _appOpenLoadGen || !rc.adsGlobalEnabled.value) {
            ad.dispose();
            return;
          }
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            if (services.isRegistered<AnalyticsService>()) {
              services<AnalyticsService>().logAdRevenue(
                adFormat: 'app_open',
                adUnitId: ad.adUnitId,
                valueMicros: valueMicros,
                currencyCode: currencyCode,
                precision: precision.name,
              );
            }
          };
          _appOpenAd = ad;
          _loadedAppOpenUnitId = adUnitId;
          _appOpenLoadTime = DateTime.now();
          _isLoadingAppOpen = false;
          appOpenCached.value = true;
          _log('AppOpenAd loaded and cached (cache=1).');
          if (!(_appOpenLoadCompleter?.isCompleted ?? true)) {
            _appOpenLoadCompleter?.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          if (gen != _appOpenLoadGen) return;
          _appOpenAd = null;
          _loadedAppOpenUnitId = null;
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

  /// Shows Cold Start Ad during Splash:
  /// - `splash_ad_style == 0`: Disabled
  /// - `splash_ad_style == 1`: App Open Ad (up to 5500ms wait)
  /// - `splash_ad_style == 2`: Interstitial Ad (up to 5500ms wait)
  Future<void> showColdStartAd({
    Duration timeout = const Duration(milliseconds: 5500),
  }) async {
    if (!isSupportedPlatform) return;
    await ensureInitialized();
    if (!rc.adsGlobalEnabled.value) return;
    final style = rc.splashAdStyle.value;
    if (style <= 0) {
      _log('Cold Start Ad skipped (splash_ad_style = 0).');
      return;
    }

    if (style == 1) {
      if (!_isAppOpenValid) {
        preloadAppOpen(forResume: false);
        final completer = _appOpenLoadCompleter;
        if (completer != null) {
          _log(
            'Waiting up to ${timeout.inMilliseconds}ms for Cold Start AppOpenAd...',
          );
          await completer.future.timeout(
            timeout,
            onTimeout: () {
              _log(
                'Cold Start AppOpenAd timed out after ${timeout.inMilliseconds}ms (kept in cache for resume if loaded).',
              );
              return false;
            },
          );
        }
      }
      if (_isAppOpenValid) {
        await _presentAppOpenAd(trigger: 'cold_start');
      }
    } else if (style == 2) {
      if (_interstitialAd == null) {
        preloadInterstitial();
        final completer = _interLoadCompleter;
        if (completer != null) {
          _log(
            'Waiting up to ${timeout.inMilliseconds}ms for Cold Start InterstitialAd...',
          );
          await completer.future.timeout(
            timeout,
            onTimeout: () {
              _log(
                'Cold Start InterstitialAd timed out after ${timeout.inMilliseconds}ms.',
              );
              return false;
            },
          );
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

  /// Shows Hot Start App Open Ad on app resume.
  /// If a resume preload triggered on `paused` is still finishing, waits briefly
  /// (up to 1200ms) so the matched ad is actually shown instead of wasted.
  Future<bool> showHotStartAppOpenAd({
    bool ignoreCooldown = false,
    Duration inFlightWait = const Duration(milliseconds: 1200),
  }) async {
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
      _log(
        'Hot Start AppOpenAd in cooldown (${hotOpenCooldownRemainingSec}s left).',
      );
      return false;
    }
    if (!_isAppOpenValid && _isLoadingAppOpen && _appOpenLoadCompleter != null) {
      _log(
        'Hot Start AppOpenAd still loading -> waiting up to ${inFlightWait.inMilliseconds}ms...',
      );
      await _appOpenLoadCompleter!.future.timeout(
        inFlightWait,
        onTimeout: () => false,
      );
    }
    if (!_isAppOpenValid) {
      _log('Hot Start AppOpenAd not ready on resume -> skipped (will preload on next pause).');
      return false;
    }
    return _presentAppOpenAd(trigger: 'hot_start');
  }

  Future<bool> _presentAppOpenAd({required String trigger}) async {
    final ad = _appOpenAd;
    if (ad == null || isShowingFullScreenAd.value) return false;

    final dismissCompleter = Completer<bool>();
    _appOpenAd = null;
    _loadedAppOpenUnitId = null;
    _appOpenLoadTime = null;
    appOpenCached.value = false;
    isShowingFullScreenAd.value = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _log('AppOpenAd shown (trigger: $trigger).');
      },
      onAdClicked: (ad) {
        if (services.isRegistered<AnalyticsService>()) {
          services<AnalyticsService>().logEvent('ad_click', {
            'ad_format': 'app_open',
            'trigger': trigger,
          });
        }
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
  // 3. INTERSTITIAL ADS (Home-Armed + Cooldown-Aware Delayed Preload)
  // ===========================================================================

  void _cancelInterReplenishTimer() {
    _interReplenishTimer?.cancel();
    _interReplenishTimer = null;
  }

  /// Schedules the next Interstitial preload 5 seconds before cooldown expires,
  /// avoiding wasted loads if the user leaves the app during cooldown.
  void _scheduleInterstitialReplenish() {
    _cancelInterReplenishTimer();
    if (!rc.adsGlobalEnabled.value ||
        !_hasEnteredHome ||
        _wasInBackground ||
        _interstitialAd != null ||
        _isLoadingInterstitial) {
      return;
    }

    final remaining = interCooldownRemainingSec;
    final delaySec = (remaining - 5).clamp(0, 3600);
    if (delaySec == 0) {
      preloadInterstitial();
      return;
    }

    _log('Scheduled Interstitial preload in ${delaySec}s (5s before cooldown ends).');
    _interReplenishTimer = Timer(Duration(seconds: delaySec), () {
      _interReplenishTimer = null;
      if (!_wasInBackground && _hasEnteredHome && rc.adsGlobalEnabled.value) {
        preloadInterstitial();
      }
    });
  }

  void preloadInterstitial() {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    final adUnitId = rc.activeInterstitialAdUnitId;
    if (adUnitId.isEmpty) {
      _log('InterstitialAd skipped (ad_unit_interstitial is empty in Remote Config).');
      return;
    }

    _cancelInterReplenishTimer();
    _isLoadingInterstitial = true;
    final gen = ++_interLoadGen;
    _interLoadCompleter = Completer<bool>();
    _log('Loading InterstitialAd ($adUnitId)...');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (gen != _interLoadGen || !rc.adsGlobalEnabled.value) {
            ad.dispose();
            return;
          }
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            if (services.isRegistered<AnalyticsService>()) {
              services<AnalyticsService>().logAdRevenue(
                adFormat: 'interstitial',
                adUnitId: ad.adUnitId,
                valueMicros: valueMicros,
                currencyCode: currencyCode,
                precision: precision.name,
              );
            }
          };
          _interstitialAd = ad;
          _loadedInterUnitId = adUnitId;
          _isLoadingInterstitial = false;
          interstitialCached.value = true;
          _log('InterstitialAd loaded and cached (cache=1).');
          if (!(_interLoadCompleter?.isCompleted ?? true)) {
            _interLoadCompleter?.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          if (gen != _interLoadGen) return;
          _interstitialAd = null;
          _loadedInterUnitId = null;
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
    _loadedInterUnitId = null;
    interstitialCached.value = false;
    isShowingFullScreenAd.value = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _log('Interstitial [$trigger] shown.');
      },
      onAdClicked: (ad) {
        if (services.isRegistered<AnalyticsService>()) {
          services<AnalyticsService>().logEvent('ad_click', {
            'ad_format': 'interstitial',
            'trigger': trigger,
          });
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        isShowingFullScreenAd.value = false;
        _lastInterDismissTime = DateTime.now();
        _log('Interstitial [$trigger] dismissed.');
        _scheduleInterstitialReplenish();
        onContinue?.call();
        if (!dismissCompleter.isCompleted) dismissCompleter.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        isShowingFullScreenAd.value = false;
        _log('Interstitial [$trigger] failed to show: ${error.message}');
        _scheduleInterstitialReplenish();
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
  // 4. NATIVE AD JIT CACHE (MAX_CACHE = 1, Just-In-Time Preload Only)
  // ===========================================================================

  /// Preloads exactly 1 Native Ad for LanguagePage (called only for first-time
  /// users during Splash when `onboardingDone == false`).
  Future<void> preloadLanguageNativeAd() async {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    final unitId = rc.activeNativeLangAdUnitId;
    if (unitId.isEmpty || rc.nativeLangStyle.value <= 0) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _platformChannel.invokeMethod<int>(
          'preloadNativeAds',
          <String, Object?>{
            'adUnitId': unitId,
            'fallbackAdUnitId': '',
          },
        );
        _log('JIT preloading 1 Native Language ad ($unitId).');
      } catch (_) {}
    } else {
      replenishNativeQueue(rc.nativeLangStyle.value);
    }
  }

  /// Preloads exactly 1 Native Ad for Onboarding step 3 when OnboardingPage opens.
  Future<void> preloadOnboardingNativeAd() async {
    if (!isSupportedPlatform || !rc.adsGlobalEnabled.value) return;
    final unitId = rc.activeNativeOnboardingAdUnitId;
    if (unitId.isEmpty || rc.nativeOnboardingStyle.value <= 0) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _platformChannel.invokeMethod<int>(
          'preloadNativeAds',
          <String, Object?>{
            'adUnitId': unitId,
            'fallbackAdUnitId': '',
          },
        );
        _log('JIT preloading 1 Native Onboarding ad ($unitId).');
      } catch (_) {}
    } else {
      replenishNativeQueue(rc.nativeOnboardingStyle.value);
    }
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

  /// Pops 1 preloaded `NativeAd` from the style queue (0ms delay) without
  /// blindly refilling the cache in the background.
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
      return ad;
    }
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
        onAdClicked: (ad) {
          if (services.isRegistered<AnalyticsService>()) {
            services<AnalyticsService>().logEvent('ad_click', {
              'ad_format': 'native',
              'style': s,
            });
          }
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          if (services.isRegistered<AnalyticsService>()) {
            services<AnalyticsService>().logAdRevenue(
              adFormat: 'native',
              adUnitId: ad.adUnitId,
              valueMicros: valueMicros,
              currencyCode: currencyCode,
              precision: precision.name,
            );
          }
        },
        onAdLoaded: (loadedAd) {
          _nativeLoadingCount[s] = ((_nativeLoadingCount[s] ?? 1) - 1).clamp(
            0,
            maxNativeCachePerStyle,
          );
          if (loadedAd is NativeAd) {
            if (queue.length < maxNativeCachePerStyle) {
              queue.add(loadedAd);
              _log(
                'NativeAd cached for $factoryId (queue=${queue.length}/$maxNativeCachePerStyle).',
              );
            } else {
              loadedAd.dispose();
            }
          }
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          _nativeLoadingCount[s] = ((_nativeLoadingCount[s] ?? 1) - 1).clamp(
            0,
            maxNativeCachePerStyle,
          );
          _log('NativeAd ($factoryId) failed to load: ${error.message}');
        },
      ),
    );
    ad.load();
  }

  void resetCooldowns() {
    _lastInterDismissTime = null;
    _lastAppOpenDismissTime = null;
    _cancelInterReplenishTimer();
    _log('Reset Interstitial & Hot Open cooldown timers.');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configRevisionWorker?.dispose();
    _cancelInterReplenishTimer();
    _disposeAppOpenCache(bumpGen: true);
    _disposeInterstitialCache(bumpGen: true);
    _disposeAllNativeQueues();
  }
}
