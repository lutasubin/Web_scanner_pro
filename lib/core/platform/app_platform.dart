import 'package:flutter/services.dart';

class AppPlatform {
  AppPlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('web_scanner_pro/platform');

  final MethodChannel _channel;

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
