import 'package:flutter/services.dart';

class AppPlatform {
  AppPlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('web_scanner_pro/platform');

  final MethodChannel _channel;
  final Set<VoidCallback> _statusesChangedListeners = <VoidCallback>{};
  final Set<VoidCallback> _historyChangedListeners = <VoidCallback>{};
  final Set<ValueChanged<String>> _openRouteListeners =
      <ValueChanged<String>>{};
  bool _handlerAttached = false;

  void _ensureHandlerAttached() {
    if (_handlerAttached) return;
    try {
      _channel.setMethodCallHandler(_handlePlatformCallback);
      _handlerAttached = true;
    } catch (_) {}
  }

  Future<dynamic> _handlePlatformCallback(MethodCall call) async {
    switch (call.method) {
      case 'onStatusesUpdated':
        for (final listener in List<VoidCallback>.from(
          _statusesChangedListeners,
        )) {
          listener();
        }
        break;
      case 'onHistoryUpdated':
        for (final listener in List<VoidCallback>.from(
          _historyChangedListeners,
        )) {
          listener();
        }
        break;
      case 'onOpenRoute':
        final route = call.arguments as String?;
        if (route != null && route.isNotEmpty) {
          for (final listener in List<ValueChanged<String>>.from(
            _openRouteListeners,
          )) {
            listener(route);
          }
        }
        break;
    }
  }

  void addStatusesChangedListener(VoidCallback listener) {
    _ensureHandlerAttached();
    _statusesChangedListeners.add(listener);
  }

  void removeStatusesChangedListener(VoidCallback listener) {
    _statusesChangedListeners.remove(listener);
  }

  void addHistoryChangedListener(VoidCallback listener) {
    _ensureHandlerAttached();
    _historyChangedListeners.add(listener);
  }

  void removeHistoryChangedListener(VoidCallback listener) {
    _historyChangedListeners.remove(listener);
  }

  void addOpenRouteListener(ValueChanged<String> listener) {
    _ensureHandlerAttached();
    _openRouteListeners.add(listener);
  }

  void removeOpenRouteListener(ValueChanged<String> listener) {
    _openRouteListeners.remove(listener);
  }

  Future<T?> invoke<T>(String method, [Map<String, Object?>? arguments]) =>
      _channel.invokeMethod<T>(method, arguments);

  Future<Map<Object?, Object?>> readMap(String method) async =>
      await invoke<Map<Object?, Object?>>(method) ?? <Object?, Object?>{};

  Future<List<Map<Object?, Object?>>> readList(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final records = await invoke<List<Object?>>(method, arguments) ?? [];
    return records
        .map((record) => (record as Map).cast<Object?, Object?>())
        .toList(growable: false);
  }
}
