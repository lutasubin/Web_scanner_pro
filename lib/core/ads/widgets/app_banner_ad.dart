import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../di/di.dart';
import '../ad_service.dart';
import '../remote_config_service.dart';

/// Renders an Anchored Adaptive Banner (or Collapsible Banner when [collapsibleFlag] is true)
/// at the bottom of a screen, controlled dynamically by Firebase Remote Config.
///
/// On Android, uses the native `com.example.dual_app/banner_ad` PlatformView
/// (`DualAppBannerPlatformView`, matching `jc/e.java` + `zl/e.java` + `yl/h.java`
/// in the original app) so `AdView(activity)` has the real `Activity` context and
/// Google AdMob's Collapsible Banner (`collapsible: bottom`) expands into the
/// half-screen overlay with the circular `⌄` collapse button (`orig_home_after_ad.png`).
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({
    super.key,
    required this.placement,
    required this.enabledFlag,
    this.collapsibleFlag,
  });

  final String placement;
  final RxBool enabledFlag;
  final RxBool? collapsibleFlag;

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  // Android PlatformView state (`com.example.dual_app/banner_ad`)
  MethodChannel? _androidViewChannel;
  bool _androidAdFailed = false;
  double _androidHeightDp = 60.0;
  int _reloadToken = 0;

  // iOS fallback state (`google_mobile_ads`)
  BannerAd? _iosBannerAd;
  AdSize? _iosAdSize;
  bool _iosLoaded = false;
  bool _iosLoading = false;

  bool? _lastCollapsible;
  String? _lastAdUnitId;
  Worker? _configWorker;

  bool get _useAndroidPlatformView =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !Get.testMode;

  RxBool _effectiveCollapsibleRx(RemoteConfigService rc) =>
      widget.collapsibleFlag ?? rc.bannerHomeCollapsible;

  @override
  void initState() {
    super.initState();
    if (services.isRegistered<RemoteConfigService>()) {
      final rc = services<RemoteConfigService>();
      _configWorker = everAll(
        [
          rc.adsGlobalEnabled,
          widget.enabledFlag,
          _effectiveCollapsibleRx(rc),
          rc.adUnitBannerAndroid,
          rc.adUnitBannerIos,
          rc.adUnitBannerCollapsibleAndroid,
          rc.adUnitBannerCollapsibleIos,
        ],
        (_) {
          if (!mounted) return;
          final shouldShow =
              rc.adsGlobalEnabled.value && widget.enabledFlag.value;
          final wantCollapsible = _effectiveCollapsibleRx(rc).value;
          final wantUnitId = wantCollapsible
              ? rc.activeCollapsibleBannerAdUnitId
              : rc.activeBannerAdUnitId;

          if (!shouldShow || wantUnitId.isEmpty) {
            _disposeIosBanner();
            setState(() {
              _androidAdFailed = false;
            });
          } else if (_lastCollapsible != wantCollapsible ||
              _lastAdUnitId != wantUnitId) {
            _lastCollapsible = wantCollapsible;
            _lastAdUnitId = wantUnitId;
            if (_useAndroidPlatformView) {
              setState(() {
                _androidAdFailed = false;
                _reloadToken++;
              });
            } else {
              _disposeIosBanner();
              _loadIosBannerIfNeeded();
            }
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant AppBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      if (_useAndroidPlatformView) {
        setState(() {
          _androidAdFailed = false;
          _reloadToken++;
        });
      } else {
        _disposeIosBanner();
        _loadIosBannerIfNeeded();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_useAndroidPlatformView) {
      _loadIosBannerIfNeeded();
    }
  }

  void _onAndroidPlatformViewCreated(int viewId) {
    final channel = MethodChannel('com.example.dual_app/banner_ad/$viewId');
    _androidViewChannel = channel;
    channel.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'adStatus') {
        final args = call.arguments;
        if (args is Map) {
          final available = args['available'] == true;
          final heightDp = (args['heightDp'] as num?)?.toDouble();
          setState(() {
            _androidAdFailed = !available;
            if (heightDp != null && heightDp > 0) {
              _androidHeightDp = heightDp;
            }
          });
        }
      }
    });
  }

  Future<void> _loadIosBannerIfNeeded() async {
    if (_useAndroidPlatformView) return;
    if (!mounted || _iosLoading || _iosBannerAd != null) return;
    if (!services.isRegistered<AdService>() ||
        !services.isRegistered<RemoteConfigService>()) {
      return;
    }
    final adService = services<AdService>();
    final rc = services<RemoteConfigService>();
    if (!adService.isSupportedPlatform) return;
    if (!rc.adsGlobalEnabled.value || !widget.enabledFlag.value) return;

    _iosLoading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final adaptiveWidth = width > 0 ? width : 320;

    // ignore: deprecated_member_use
    final size =
        // ignore: deprecated_member_use
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          adaptiveWidth,
        );
    if (!mounted || size == null) {
      _iosLoading = false;
      return;
    }

    final isCollapsible = _effectiveCollapsibleRx(rc).value;
    _lastCollapsible = isCollapsible;

    final adUnitId = isCollapsible
        ? rc.activeCollapsibleBannerAdUnitId
        : rc.activeBannerAdUnitId;
    if (adUnitId.isEmpty) {
      _iosLoading = false;
      return;
    }
    _lastAdUnitId = adUnitId;

    final request = isCollapsible
        ? const AdRequest(extras: <String, String>{'collapsible': 'bottom'})
        : const AdRequest();

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _iosBannerAd = ad as BannerAd;
            _iosAdSize = size;
            _iosLoaded = true;
            _iosLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _iosBannerAd = null;
            _iosLoaded = false;
            _iosLoading = false;
          });
        },
      ),
    );

    await banner.load();
  }

  void _disposeIosBanner() {
    _iosBannerAd?.dispose();
    _iosBannerAd = null;
    _iosAdSize = null;
    _iosLoaded = false;
    _iosLoading = false;
  }

  @override
  void dispose() {
    _configWorker?.dispose();
    _androidViewChannel?.setMethodCallHandler(null);
    _disposeIosBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!services.isRegistered<AdService>() ||
        !services.isRegistered<RemoteConfigService>()) {
      return const SizedBox.shrink();
    }
    final adService = services<AdService>();
    final rc = services<RemoteConfigService>();
    if (!adService.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final enabled = rc.adsGlobalEnabled.value && widget.enabledFlag.value;
      if (!enabled) return const SizedBox.shrink();

      final isCollapsible = _effectiveCollapsibleRx(rc).value;
      final adUnitId = isCollapsible
          ? rc.activeCollapsibleBannerAdUnitId
          : rc.activeBannerAdUnitId;
      if (adUnitId.isEmpty) return const SizedBox.shrink();

      if (_useAndroidPlatformView) {
        if (_androidAdFailed) return const SizedBox.shrink();
        final screenWidthDp = MediaQuery.sizeOf(context).width.truncate();
        _lastCollapsible = isCollapsible;
        _lastAdUnitId = adUnitId;

        return ColoredBox(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: _androidHeightDp,
              child: AndroidView(
                key: ValueKey<String>(
                  'dual_app_banner_${widget.placement}_${adUnitId}_${isCollapsible}_$_reloadToken',
                ),
                viewType: 'com.example.dual_app/banner_ad',
                creationParams: <String, Object?>{
                  'placement': widget.placement,
                  'isCollapsible': isCollapsible,
                  'adUnitId': adUnitId,
                  'widthDp': screenWidthDp > 0 ? screenWidthDp : 360,
                },
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onAndroidPlatformViewCreated,
              ),
            ),
          ),
        );
      }

      if (_iosLoaded && _iosBannerAd != null && _iosAdSize != null) {
        final adHeight = _iosAdSize!.height.toDouble();
        final adWidth = _iosAdSize!.width.toDouble();
        return ColoredBox(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: adHeight,
              child: Center(
                child: SizedBox(
                  width: adWidth,
                  height: adHeight,
                  child: AdWidget(ad: _iosBannerAd!),
                ),
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
