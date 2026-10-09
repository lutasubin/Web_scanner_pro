import 'package:flutter/material.dart';

class AppPreferences {
  const AppPreferences({this.theme = 'system', this.captureEnabled = false});

  factory AppPreferences.fromMap(Map<Object?, Object?> map) => AppPreferences(
    theme: map['theme'] as String? ?? 'system',
    captureEnabled: map['captureEnabled'] as bool? ?? false,
  );

  final String theme;
  final bool captureEnabled;

  ThemeMode get themeMode => switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
