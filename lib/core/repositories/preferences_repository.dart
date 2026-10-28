import 'package:get/get.dart';

import '../models/app_preferences.dart';
import '../platform/app_platform.dart';

class PreferencesRepository {
  PreferencesRepository(this._platform);

  final AppPlatform _platform;
  final value = const AppPreferences().obs;
  String? initializationError;
  Future<void>? _loadFuture;

  Future<void> load() => _loadFuture = _doLoad();

  Future<void> ensureLoaded() => _loadFuture ?? load();

  Future<void> _doLoad() async {
    value.value = AppPreferences.fromMap(
      await _platform.readMap('getSettings'),
    );
    initializationError = null;
  }

  Future<void> update(Map<String, Object?> changes) async {
    await _platform.invoke<void>('updateSettings', changes);
    await load();
  }
}
