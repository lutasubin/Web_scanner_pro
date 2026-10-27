import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../di/di.dart';
import '../remote_config_service.dart';
import 'app_native_ad.dart';

/// Displays the Exit Confirmation Bottom Sheet on HomePage back press (`orig_real_exit_dialog.png`),
/// embedding the Native Ad controlled by `native_exit_style` (`exit_style = 2` in original app)
/// flush edge-to-edge at the bottom of the sheet.
Future<bool> showExitAppDialog(BuildContext context) async {
  final rc = services.isRegistered<RemoteConfigService>()
      ? services<RemoteConfigService>()
      : null;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF1BD741),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 30,
                  color: Color(0xFF1BD741),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Are you sure you want to leave the app?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1F1D),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('exit-dialog-cancel'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 26,
                            color: Color(0xFF1C1F1D),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8C9690),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    key: const Key('exit-dialog-confirm'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 26,
                            color: Color(0xFF1C1F1D),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Leave Anyway',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8C9690),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rc != null)
            AppNativeAd(
              placement: 'exit_dialog',
              styleRx: rc.nativeExitStyle,
            ),
        ],
      ),
    ),
  );

  if (result == true) {
    await SystemNavigator.pop();
    return true;
  }
  return false;
}
