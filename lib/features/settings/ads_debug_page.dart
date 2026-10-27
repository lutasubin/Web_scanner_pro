import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_native_ad.dart';
import '../../core/ads/widgets/exit_app_dialog.dart';
import '../../core/di/di.dart';

/// Interactive Test Ads & Firebase Remote Config Inspector (`web-b0480`).
/// Lets you inspect & fetch Remote Config flags, toggle placements/styles live,
/// test-trigger Cold Start / Hot Open / Interstitial Ads, and preview all 5 Native Ad templates.
class AdsDebugPage extends StatefulWidget {
  const AdsDebugPage({super.key});

  @override
  State<AdsDebugPage> createState() => _AdsDebugPageState();
}

class _AdsDebugPageState extends State<AdsDebugPage> {
  int _previewStyle = 6;
  bool _fetching = false;

  RemoteConfigService get _rc => services<RemoteConfigService>();
  AdService get _adService => services<AdService>();

  Future<void> _fetchRemoteConfig() async {
    if (_fetching) return;
    setState(() => _fetching = true);
    final updated = await _rc.fetchAndActivate();
    if (!mounted) return;
    setState(() => _fetching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'Fetched & activated new Remote Config values from web-b0480!'
              : 'Remote Config synced (status: ${_rc.lastFetchStatus.value}).',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F6F8),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        'Ads & Remote Config Test',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      actions: [
        IconButton(
          tooltip: 'Fetch Firebase Remote Config',
          onPressed: _fetching ? null : _fetchRemoteConfig,
          icon: _fetching
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_sync_rounded, color: Color(0xFF08C567)),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildStatusBanner(),
                const SizedBox(height: 14),
                _buildQuickTriggerCard(context),
                const SizedBox(height: 14),
                _buildAdUnitIdsCard(context),
                const SizedBox(height: 14),
                _buildTemplateGalleryCard(),
                const SizedBox(height: 14),
                _buildRemoteConfigControlsCard(),
                const SizedBox(height: 14),
                _buildEventLogCard(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildStatusBanner() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF08C567),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Firebase Project: web-b0480 (Google Test Ads)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _fetching ? null : _fetchRemoteConfig,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Sync RC'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RC Status: ${_rc.lastFetchStatus.value} · '
            'AppOpen Cache: ${_adService.appOpenCached.value ? "READY" : "EMPTY"} · '
            'Inter Cache: ${_adService.interstitialCached.value ? "READY" : "EMPTY"}',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF4E5D55)),
          ),
        ],
      ),
    ),
  );

  Widget _buildQuickTriggerCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Test Ad Triggers (App Open / Interstitial / Exit Dialog)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF08C567),
                ),
                onPressed: () => _adService.showHotStartAppOpenAd(
                  ignoreCooldown: true,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Show App Open Ad'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                ),
                onPressed: () => _adService.showInterstitial(
                  trigger: 'debug_test',
                  configOn: true,
                  ignoreCooldown: true,
                ),
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                label: const Text('Show Interstitial Ad'),
              ),
              OutlinedButton.icon(
                onPressed: () => showExitAppDialog(context),
                icon: const Icon(Icons.exit_to_app_rounded, size: 17),
                label: const Text('Test Exit Dialog (Native)'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _adService.resetCooldowns();
                  _adService.preloadAppOpen();
                  _adService.preloadInterstitial();
                },
                icon: const Icon(Icons.timer_off_outlined, size: 17),
                label: const Text('Reset Cooldown & Preload'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildAdUnitIdsCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. Remote Config Ad Unit IDs (Thay đổi / Bật tắt từ xa)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Các mã Ad Unit lấy trực tiếp từ Firebase Remote Config (nhấn vào dòng để sửa thử nghiệm hoặc để trống để tắt loại quảng cáo đó):',
            style: TextStyle(fontSize: 12, color: Color(0xFF4E5D55)),
          ),
          const Divider(height: 16),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_app_open_android',
            rx: _rc.adUnitAppOpenAndroid,
          ),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_interstitial_android',
            rx: _rc.adUnitInterstitialAndroid,
          ),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_banner_android',
            rx: _rc.adUnitBannerAndroid,
          ),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_banner_collapsible_android',
            rx: _rc.adUnitBannerCollapsibleAndroid,
          ),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_native_android',
            rx: _rc.adUnitNativeAndroid,
          ),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_native_collab_android',
            rx: _rc.adUnitNativeCollabAndroid,
          ),
          _buildAdUnitRow(
            context,
            rcKey: 'ad_unit_native_fallback_android',
            rx: _rc.adUnitNativeFallbackAndroid,
          ),
        ],
      ),
    ),
  );

  Widget _buildAdUnitRow(
    BuildContext context, {
    required String rcKey,
    required RxString rx,
  }) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(
      rcKey,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    subtitle: Text(
      rx.value.isEmpty ? '(Đang để trống = Tắt)' : rx.value,
      style: TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        color: rx.value.isEmpty
            ? const Color(0xFFD32F2F)
            : const Color(0xFF08C567),
      ),
    ),
    trailing: const Icon(Icons.edit_outlined, size: 18),
    onTap: () async {
      final ctrl = TextEditingController(text: rx.value);
      final updated = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(rcKey, style: const TextStyle(fontSize: 15)),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Ad Unit ID (để trống để tắt)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      );
      if (updated != null) {
        rx.value = updated;
      }
    },
  );

  Widget _buildTemplateGalleryCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. 6 Mẫu Native Ad Templates (Styles 1..5 + Style 6 Native Collab)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(6, (idx) {
              final style = idx + 1;
              final selected = _previewStyle == style;
              final label = style == 6 ? 'Style 6 (Collab)' : 'Style $style';
              return ChoiceChip(
                key: Key('chip-style-$style'),
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() => _previewStyle = style),
              );
            }),
          ),
          const SizedBox(height: 10),
          AppNativeAd(
            key: ValueKey('debug-native-$_previewStyle'),
            placement: 'debug_inspector',
            styleOverride: _previewStyle,
          ),
        ],
      ),
    ),
  );

  Widget _buildRemoteConfigControlsCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4. Remote Config Switches & Styles (Live Override)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const Divider(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'ads_global_enabled (!unShowAd)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text('Công tắc tổng bật/tắt toàn bộ quảng cáo'),
            value: _rc.adsGlobalEnabled.value,
            activeTrackColor: const Color(0xFF08C567),
            onChanged: (v) => _rc.adsGlobalEnabled.value = v,
          ),
          _buildStyleDropdown(
            label: 'splash_ad_style (0=Off, 1=AppOpen, 2=Inter)',
            current: _rc.splashAdStyle.value,
            max: 2,
            onChanged: (v) => _rc.splashAdStyle.value = v,
          ),
          _buildStyleDropdown(
            label: 'native_lang_style (Language Page: 0..6, 6=Collab)',
            current: _rc.nativeLangStyle.value,
            max: 6,
            onChanged: (v) => _rc.nativeLangStyle.value = v,
          ),
          _buildStyleDropdown(
            label: 'native_home_collab_style (Home Bottom: 0=Banner, 6=Collab)',
            current: _rc.nativeHomeCollabStyle.value,
            max: 6,
            onChanged: (v) => _rc.nativeHomeCollabStyle.value = v,
          ),
          _buildStyleDropdown(
            label: 'native_list_style (Chat/Files List index=1: 0..6)',
            current: _rc.nativeListStyle.value,
            max: 6,
            onChanged: (v) => _rc.nativeListStyle.value = v,
          ),
          _buildStyleDropdown(
            label: 'native_exit_style (Home Exit Dialog: 0..6)',
            current: _rc.nativeExitStyle.value,
            max: 6,
            onChanged: (v) => _rc.nativeExitStyle.value = v,
          ),
          const Divider(height: 18),
          _buildFlagToggle('hot_open_ad_enabled', _rc.hotOpenAdEnabled),
          _buildFlagToggle('inter_web_into', _rc.interWebInto),
          _buildFlagToggle('inter_web_back', _rc.interWebBack),
          _buildFlagToggle('inter_status_into', _rc.interStatusInto),
          _buildFlagToggle('inter_status_back', _rc.interStatusBack),
          _buildFlagToggle('inter_history_into', _rc.interHistoryInto),
          _buildFlagToggle('inter_history_back', _rc.interHistoryBack),
          _buildFlagToggle('inter_direct_chat_into', _rc.interDirectChatInto),
          _buildFlagToggle('inter_direct_chat_back', _rc.interDirectChatBack),
          _buildFlagToggle('inter_files_into', _rc.interFilesInto),
          _buildFlagToggle('inter_files_back', _rc.interFilesBack),
          const Divider(height: 18),
          _buildFlagToggle('banner_home_enabled', _rc.bannerHomeEnabled),
          _buildFlagToggle(
            'banner_home_collapsible',
            _rc.bannerHomeCollapsible,
          ),
          _buildFlagToggle('banner_web_enabled', _rc.bannerWebEnabled),
          _buildFlagToggle('banner_status_enabled', _rc.bannerStatusEnabled),
          _buildFlagToggle('banner_history_enabled', _rc.bannerHistoryEnabled),
          _buildFlagToggle('banner_files_enabled', _rc.bannerFilesEnabled),
          _buildFlagToggle(
            'banner_direct_chat_enabled',
            _rc.bannerDirectChatEnabled,
          ),
        ],
      ),
    ),
  );

  Widget _buildStyleDropdown({
    required String label,
    required int current,
    required int max,
    required ValueChanged<int> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        DropdownButton<int>(
          value: current.clamp(0, max),
          items: List.generate(
            max + 1,
            (v) => DropdownMenuItem<int>(
              value: v,
              child: Text(v == 0 ? '0 (Off)' : 'Style $v'),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    ),
  );

  Widget _buildFlagToggle(String keyName, RxBool rx) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(
      keyName,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
    ),
    value: rx.value,
    activeTrackColor: const Color(0xFF08C567),
    onChanged: (v) => rx.value = v,
  );

  Widget _buildEventLogCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '4. Ad SDK Event Log',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: _adService.adEventLogs.clear,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_adService.adEventLogs.isEmpty)
            const Text(
              'No ad events logged yet.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8C9690)),
            )
          else
            ..._adService.adEventLogs.take(20).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF2C3631),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
