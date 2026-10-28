import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Centralized Firebase Analytics logger matching the original app's
/// (`scan.web.dualapp.webscanner.appcloner v1.0.32`) event names and parameters.
///
/// All calls are non-blocking (`unawaited`) and safe in widget tests or offline mode.
class AnalyticsService {
  AnalyticsService();

  final recentEvents = <String>[].obs;
  final List<_PendingEvent> _pendingBeforeInit = <_PendingEvent>[];
  bool _flushing = false;

  /// Non-blocking fire-and-forget event logger matching `dt.l.a0(eventName)`
  /// and `com.example.dual_app.webs.s.a(eventName, params)`.
  void logEvent(String name, [Map<String, Object?>? parameters]) {
    final sanitized = _sanitizeParams(parameters);
    _recordDebugLog(name, sanitized);
    unawaited(_sendOrQueue(name, sanitized));
  }

  /// Logs ad impression / paid revenue event (`logAdRevenue` in `tc/i.java:132-146`).
  void logAdRevenue({
    required String adFormat,
    required String adUnitId,
    required double valueMicros,
    required String currencyCode,
    String? precision,
  }) {
    logEvent('ad_impression', <String, Object?>{
      'ad_platform': 'admob',
      'ad_format': adFormat,
      'ad_unit_name': adUnitId,
      'value': valueMicros / 1000000.0,
      'currency': currencyCode,
      'precision': ?precision,
    });
  }

  /// Flushes any events queued while `Firebase.initializeApp()` was running in the background.
  Future<void> flushPending() async {
    if (_flushing || _pendingBeforeInit.isEmpty) return;
    if (Firebase.apps.isEmpty) return;
    _flushing = true;
    try {
      final copy = List<_PendingEvent>.from(_pendingBeforeInit);
      _pendingBeforeInit.clear();
      for (final item in copy) {
        await _dispatchToFirebase(item.name, item.parameters);
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _sendOrQueue(
    String name,
    Map<String, Object>? parameters,
  ) async {
    if (Firebase.apps.isEmpty) {
      if (_pendingBeforeInit.length < 40) {
        _pendingBeforeInit.add(_PendingEvent(name, parameters));
      }
      return;
    }
    await flushPending();
    await _dispatchToFirebase(name, parameters);
  }

  Future<void> _dispatchToFirebase(
    String name,
    Map<String, Object>? parameters,
  ) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] skipped ($name): $e');
      }
    }
  }

  Map<String, Object>? _sanitizeParams(Map<String, Object?>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final out = <String, Object>{};
    raw.forEach((key, value) {
      if (value == null) return;
      if (value is String || value is num) {
        out[key] = value;
      } else if (value is bool) {
        out[key] = value ? 1 : 0;
      } else {
        out[key] = value.toString();
      }
    });
    return out.isEmpty ? null : out;
  }

  void _recordDebugLog(String name, Map<String, Object>? params) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final suffix = (params == null || params.isEmpty) ? '' : ' $params';
    recentEvents.insert(0, '[$hh:$mm:$ss] $name$suffix');
    if (recentEvents.length > 60) {
      recentEvents.removeLast();
    }
    if (kDebugMode) {
      debugPrint('[Analytics] logEvent: $name$suffix');
    }
  }
}

class _PendingEvent {
  const _PendingEvent(this.name, this.parameters);
  final String name;
  final Map<String, Object>? parameters;
}
