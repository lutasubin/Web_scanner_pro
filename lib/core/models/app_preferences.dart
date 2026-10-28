import 'package:flutter/material.dart';

class AppPreferences {
  const AppPreferences({
    this.theme = 'system',
    this.onboardingDone = false,
    this.languageCode = 'vi',
    this.showHomeHand = true,
    this.shownNotifyDialog = false,
    this.shownStorageDialog = false,
    this.captureEnabled = true,
  });

  factory AppPreferences.fromMap(Map<Object?, Object?> map) => AppPreferences(
    theme: map['theme'] as String? ?? 'system',
    onboardingDone: map['onboardingDone'] as bool? ?? false,
    languageCode: map['languageCode'] as String? ?? 'vi',
    showHomeHand: map['showHomeHand'] as bool? ?? true,
    shownNotifyDialog: map['shownNotifyDialog'] as bool? ?? false,
    shownStorageDialog: map['shownStorageDialog'] as bool? ?? false,
    captureEnabled: map['captureEnabled'] as bool? ?? true,
  );

  final String theme;
  final bool onboardingDone;
  final String languageCode;
  final bool showHomeHand;
  final bool shownNotifyDialog;
  final bool shownStorageDialog;
  final bool captureEnabled;

  ThemeMode get themeMode => switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
