import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../di/di.dart';
import '../ad_service.dart';
import '../ad_test_ids.dart';
import '../remote_config_service.dart';

/// Renders a Google AdMob Native Ad using the exact XML Template Styles and
/// `com.example.dual_app/native_ad` PlatformView + shared 3-ad queue architecture
/// from the original app (`jc/h.java`, `yl/e.java`, `xf/b.java`, `jc/g.java`, `jc/a.java`):
/// - `0`: Disabled (hidden)
/// - `1`: `ad_native.xml` (`#F5F5F5` bg, 45dp icon, `#666666` 12sp text, `#D9D9D9` `AD` badge, 120dp MediaView, `#00C667` 8dp-radius bottom CTA)
/// - `2`: `ad_native_small.xml` (`#F5F5F5` bg, 80dp minHeight row, 45dp icon, `#666666` text, `#00C667` 8dp-radius right CTA)
/// - `3`: `ad_native_small_hollow.xml` (`#F5F5F5` bg, 80dp minHeight row, `#00C667` 1dp-stroke hollow right CTA)
/// - `4`: `ad_native_btn_top.xml` (`#F5F5F5` bg, top full-width `#00C667` CTA + bottom 45dp icon/text row)
/// - `5`: `ad_native_btn_bottom.xml` (`#F5F5F5` bg, top 45dp icon/text row + bottom full-width `#00C667` CTA)
/// - `6`: `ad_native_collab.xml` (Collapsible Native Ad with circular `⌄` collapse button)
class AppNativeAd extends StatefulWidget {
  const AppNativeAd({
    super.key,
    required this.placement,
    this.styleRx,
    this.styleOverride,
    this.forcePreview = false,
  });

  final String placement;
  final RxInt? styleRx;
  final int? styleOverride;
  final bool forcePreview;

  @override
  State<AppNativeAd> createState() => _AppNativeAdState();
}

class _AppNativeAdState extends State<AppNativeAd> {
  // Android PlatformView (`com.example.dual_app/native_ad` -> `DualAppNativePlatformView`)
  MethodChannel? _androidViewChannel;
  bool _androidAdFailed = false;
  bool _isCollabCollapsed = false;
  int _reloadToken = 0;
  int _lastStyle = 0;
  String? _lastAdUnitId;

  // iOS fallback (`google_mobile_ads`)
  NativeAd? _iosNativeAd;
  bool _iosLoaded = false;

  Worker? _styleWorker;

  bool get _useAndroidPlatformView =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !Get.testMode;

  int get _effectiveStyle {
    final raw = widget.styleOverride ?? widget.styleRx?.value ?? 0;
    return raw.clamp(0, 6);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.forcePreview) {
      if (!_useAndroidPlatformView) {
        _loadIosAdForCurrentStyle();
      }
      if (services.isRegistered<RemoteConfigService>()) {
        final rc = services<RemoteConfigService>();
        _styleWorker = everAll(
          [
            rc.adsGlobalEnabled,
            if (widget.styleRx != null) widget.styleRx!,
            rc.adUnitNativeAndroid,
            rc.adUnitNativeLangAndroid,
            rc.adUnitNativeCollabAndroid,
            rc.adUnitNativeOnboardingAndroid,
            rc.adUnitNativeFallbackAndroid,
            rc.adUnitNativeIos,
            rc.adUnitNativeLangIos,
            rc.adUnitNativeCollabIos,
            rc.adUnitNativeOnboardingIos,
            rc.adUnitNativeFallbackIos,
          ],
          (_) {
            if (!mounted) return;
            if (_useAndroidPlatformView) {
              final nextStyle = _effectiveStyle;
              final nextUnit = _resolvePrimaryAdUnitId(nextStyle, rc);
              if (nextStyle != _lastStyle || nextUnit != _lastAdUnitId) {
                setState(() {
                  _androidAdFailed = false;
                  _isCollabCollapsed = false;
                  _reloadToken++;
                });
              } else {
                setState(() {});
              }
            } else {
              _loadIosAdForCurrentStyle();
            }
          },
        );
      }
    }
  }

  void _onAndroidPlatformViewCreated(int viewId) {
    final channel = MethodChannel('com.example.dual_app/native_ad/$viewId');
    _androidViewChannel = channel;
    channel.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'adStatus') {
        final args = call.arguments;
        if (args is Map) {
          final available = args['available'] == true;
          if (mounted) {
            setState(() {
              _androidAdFailed = !available;
            });
          }
          if (available && services.isRegistered<AdService>()) {
            services<AdService>().refreshNativeQueueCount();
          }
        }
      }
    });
  }

  void _toggleCollabCollapsed() {
    final next = !_isCollabCollapsed;
    setState(() {
      _isCollabCollapsed = next;
    });
    _androidViewChannel?.invokeMethod<void>(
      'setCollapsed',
      <String, Object?>{'collapsed': next},
    );
  }

  String _resolvePrimaryAdUnitId(int style, RemoteConfigService rc) {
    if (widget.placement == 'language_page') {
      return rc.activeNativeLangAdUnitId;
    }
    if (widget.placement == 'onboarding_page') {
      return rc.activeNativeOnboardingAdUnitId;
    }
    return style == 6
        ? rc.activeNativeCollabAdUnitId
        : rc.activeNativeAdUnitId;
  }

  void _loadIosAdForCurrentStyle() {
    if (_useAndroidPlatformView) return;
    if (!services.isRegistered<AdService>() ||
        !services.isRegistered<RemoteConfigService>()) {
      return;
    }
    final adService = services<AdService>();
    final rc = services<RemoteConfigService>();
    if (!adService.isSupportedPlatform) return;

    final style = _effectiveStyle;
    final primaryUnitId = _resolvePrimaryAdUnitId(style, rc);
    if (!rc.adsGlobalEnabled.value || style <= 0 || primaryUnitId.isEmpty) {
      _disposeIosAd();
      if (mounted) setState(() {});
      return;
    }

    if (_iosNativeAd != null &&
        _lastStyle == style &&
        _lastAdUnitId == primaryUnitId) {
      return;
    }
    _disposeIosAd();
    _lastStyle = style;
    _lastAdUnitId = primaryUnitId;
    _isCollabCollapsed = false;

    final cached = adService.popCachedNativeAd(style);
    if (cached != null) {
      setState(() {
        _iosNativeAd = cached;
        _iosLoaded = true;
      });
      return;
    }

    _loadIosWithAdUnit(style, primaryUnitId, isRetry: false);
  }

  void _loadIosWithAdUnit(int style, String adUnitId, {required bool isRetry}) {
    if (adUnitId.isEmpty) return;
    final factoryId = AdTestIds.factoryIdForStyle(style);
    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          setState(() {
            _iosNativeAd = loadedAd as NativeAd;
            _iosLoaded = true;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          if (!mounted) return;
          if (!isRetry && services.isRegistered<RemoteConfigService>()) {
            final fallbackId =
                services<RemoteConfigService>().activeNativeFallbackAdUnitId;
            if (fallbackId.isNotEmpty && fallbackId != adUnitId) {
              _loadIosWithAdUnit(style, fallbackId, isRetry: true);
              return;
            }
          }
          setState(() {
            _iosNativeAd = null;
            _iosLoaded = false;
          });
        },
      ),
    );
    ad.load();
  }

  void _disposeIosAd() {
    _iosNativeAd?.dispose();
    _iosNativeAd = null;
    _iosLoaded = false;
  }

  /// Exact template heights matching the original app's `res/layout/ad_native*.xml`:
  /// - Style 1 (`ad_native.xml`): 260dp
  /// - Style 2 (`ad_native_small.xml`): 80dp (`minHeight="80dp"`)
  /// - Style 3 (`ad_native_small_hollow.xml`): 80dp (`minHeight="80dp"`)
  /// - Style 4 (`ad_native_btn_top.xml`): 146dp
  /// - Style 5 (`ad_native_btn_bottom.xml`): 158dp
  /// - Style 6 (`ad_native_collab.xml`): 254dp expanded / 80dp collapsed
  static double heightForStyle(int style, {bool isCollabCollapsed = false}) {
    switch (style) {
      case 1:
        return 260;
      case 2:
      case 3:
        return 80;
      case 4:
        return 146;
      case 5:
        return 168;
      case 6:
        return isCollabCollapsed ? 80 : 254;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _styleWorker?.dispose();
    _androidViewChannel?.setMethodCallHandler(null);
    _disposeIosAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forcePreview) {
      final s = _effectiveStyle;
      if (s <= 0) return const SizedBox.shrink();
      return NativeAdTemplatePreview(style: s, placement: widget.placement);
    }

    if (!services.isRegistered<AdService>() ||
        !services.isRegistered<RemoteConfigService>()) {
      return const SizedBox.shrink();
    }
    final adService = services<AdService>();
    final rc = services<RemoteConfigService>();
    if (!adService.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    if (widget.styleRx != null) {
      return Obx(() {
        final style = _effectiveStyle;
        if (!rc.adsGlobalEnabled.value || style <= 0) {
          return const SizedBox.shrink();
        }
        return _buildPlatformAd(style, rc);
      });
    }

    final style = _effectiveStyle;
    if (!rc.adsGlobalEnabled.value || style <= 0) {
      return const SizedBox.shrink();
    }
    return _buildPlatformAd(style, rc);
  }

  Widget _buildPlatformAd(int style, RemoteConfigService rc) {
    final adUnitId = _resolvePrimaryAdUnitId(style, rc);
    if (adUnitId.isEmpty) return const SizedBox.shrink();

    if (_useAndroidPlatformView) {
      if (_androidAdFailed) return const SizedBox.shrink();
      _lastStyle = style;
      _lastAdUnitId = adUnitId;

      final adBox = ColoredBox(
        color: const Color(0xFFF5F5F5),
        child: SizedBox(
          width: double.infinity,
          height: heightForStyle(
            style,
            isCollabCollapsed: _isCollabCollapsed,
          ),
          child: AndroidView(
            key: ValueKey<String>(
              'dual_app_native_${widget.placement}_${style}_${adUnitId}_$_reloadToken',
            ),
            viewType: 'com.example.dual_app/native_ad',
            creationParams: <String, Object?>{
              'placement': widget.placement,
              'style': style,
              'configOn': true,
              'adUnitId': adUnitId,
              'fallbackAdUnitId': rc.activeNativeFallbackAdUnitId,
              'collapsed': _isCollabCollapsed,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onAndroidPlatformViewCreated,
          ),
        ),
      );

      if (style != 6) return adBox;

      // Style 6: Circular collapse/expand chevron button at the top-right corner (`orig_home_after_ad.png`)
      return Stack(
        clipBehavior: Clip.none,
        children: [
          adBox,
          Positioned(
            top: 8,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                key: Key('native-collab-toggle-${widget.placement}'),
                customBorder: const CircleBorder(),
                onTap: _toggleCollabCollapsed,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _isCollabCollapsed
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: const Color(0xFF3C4043),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_iosLoaded && _iosNativeAd != null && _lastStyle == style) {
      return SizedBox(
        width: double.infinity,
        height: heightForStyle(
          style,
          isCollabCollapsed: _isCollabCollapsed,
        ),
        child: AdWidget(ad: _iosNativeAd!),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Renders an authentic Google AdMob Test Native Ad preview using the exact
/// geometry and colors of the original app (`jadx_res/resources/res/`):
/// - Background: `@color/ad_back` (`#F5F5F5`)
/// - Headline & Body: `@color/ad_text` (`#666666`), `12sp`
/// - Attribution badge: `@style/AdAttribution` (`AD`, `#D9D9D9` bg, `#FFFFFF` text, `12sp`)
/// - CTA Button: `@color/green` (`#00C667`) with `8dp` corner radius (`@drawable/ad_button_bg` / `@drawable/circle_border`)
class NativeAdTemplatePreview extends StatefulWidget {
  const NativeAdTemplatePreview({
    super.key,
    required this.style,
    required this.placement,
  });

  final int style;
  final String placement;

  @override
  State<NativeAdTemplatePreview> createState() =>
      _NativeAdTemplatePreviewState();
}

class _NativeAdTemplatePreviewState extends State<NativeAdTemplatePreview> {
  bool _collabCollapsed = false;

  void _onTestAdTap(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'AdMob Test Native Ad clicked (Style ${widget.style} · ${widget.placement})',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style.clamp(1, 6);
    final padH = s == 1 ? 20.0 : 12.0;
    final card = Material(
      color: const Color(0xFFF5F5F5),
      child: InkWell(
        key: Key('native-ad-${widget.placement}-style-$s'),
        onTap: () => _onTestAdTap(context),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padH, 10, padH, 12),
              child: switch (s) {
                1 => _buildStyle1LargeMedia(),
                2 => _buildStyle2SmallSolid(),
                3 => _buildStyle3SmallHollow(),
                4 => _buildStyle4BtnTop(),
                5 => _buildStyle5BtnBottom(),
                _ =>
                  _collabCollapsed
                      ? _buildStyle2SmallSolid()
                      : _buildStyle1LargeMedia(),
              },
            ),
            // AdChoices info icon at top-right (`ADCHOICES_TOP_RIGHT` in `yl/d.java:51`, visible in `orig_real_exit_dialog.png`)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFF00A4E4),
              ),
            ),
          ],
        ),
      ),
    );
    if (s != 6) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: 8,
          right: 22,
          child: Material(
            color: Colors.white.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              key: Key('native-collab-toggle-${widget.placement}'),
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _collabCollapsed = !_collabCollapsed),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  _collabCollapsed
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF3C4043),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: SizedBox(
          height: 55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Headline (`@id/ad_headline`: `12sp`, `#666666`)
              const Text(
                'Test Ad : Investment Management',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Grey `AD` badge (`#D9D9D9` matching `@style/AdAttribution` in `orig_real_exit_dialog.png`)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    color: const Color(0xFFD9D9D9),
                    child: const Text(
                      'AD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Body (`@id/ad_body`: `12sp`, `#666666`)
                  const Expanded(
                    child: Text(
                      'Mutual Funds',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildFullWidthCtaButton() => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 14, bottom: 13),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF00C667),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'Learn More',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // Style 1: `ad_native.xml` (Top Info + 120dp MediaView + Bottom `#00C667` 8dp CTA)
  Widget _buildStyle1LargeMedia() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildInfoRow(),
      const SizedBox(height: 5),
      Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF202124),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Test Ad · MediaView (120dp)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 24),
      _buildFullWidthCtaButton(),
    ],
  );

  // Style 2: `ad_native_small.xml` (80dp minHeight Row + Right `#00C667` 8dp CTA)
  Widget _buildStyle2SmallSolid() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Row(
      children: [
        Expanded(child: _buildInfoRow()),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF00C667),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Learn More',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  // Style 3: `ad_native_small_hollow.xml` (80dp minHeight Row + Right `#00C667` 1dp Outlined CTA)
  Widget _buildStyle3SmallHollow() => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Row(
      children: [
        Expanded(child: _buildInfoRow()),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00C667), width: 1),
          ),
          child: const Text(
            'Learn More',
            style: TextStyle(
              color: Color(0xFF00C667),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  // Style 4: `ad_native_btn_top.xml` (Top Full-Width `#00C667` CTA + 24dp margin + Bottom Info Row)
  Widget _buildStyle4BtnTop() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildFullWidthCtaButton(),
      const SizedBox(height: 24),
      _buildInfoRow(),
    ],
  );

  // Style 5: `ad_native_btn_bottom.xml` (Top Icon + Info Row + Bottom Full-Width `#0FBC5D` CTA)
  Widget _buildStyle5BtnBottom() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFD9DADB),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Test Ad : Investment Management',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      color: const Color(0xFFD9D9D9),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'Mutual Funds',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0FBC5D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'NEXT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
