import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/theme/app_theme.dart';
import '../sessions/session_card.dart';
import '../sessions/web_session.dart';
import 'home_page.dart';

void _noop() {}

@Preview(name: 'Home - no account', group: 'Web Scanner', size: Size(343, 716))
Widget homeWithoutAccountPreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  home: HomeDashboard(
    activeSession: null,
    loading: false,
    error: '',
    onSettings: _noop,
    onAccount: _noop,
    onAccountManagement: _noop,
    onDualApp: _noop,
    onDeletedMessages: _noop,
    onDownloads: _noop,
    onStatusSaver: _noop,
    onDirectChat: _noop,
    onHowToUse: _noop,
  ),
);

@Preview(
  name: 'Home - active account',
  group: 'Web Scanner',
  size: Size(343, 716),
)
Widget homeWithAccountPreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  home: HomeDashboard(
    activeSession: const WebSession(
      id: 'personal',
      name: 'User 1',
      isDefault: true,
      isActive: true,
    ),
    loading: false,
    error: '',
    onSettings: _noop,
    onAccount: _noop,
    onAccountManagement: _noop,
    onDualApp: _noop,
    onDeletedMessages: _noop,
    onDownloads: _noop,
    onStatusSaver: _noop,
    onDirectChat: _noop,
    onHowToUse: _noop,
  ),
);

@Preview(name: 'Account Management', group: 'Web Scanner', size: Size(343, 716))
Widget accountManagementPreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  home: Scaffold(
    appBar: AppBar(
      title: const Text('Account Management'),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.help_outline_rounded),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        SessionCard(
          title: 'User 1',
          enabled: true,
          onOpen: _noop,
          onRename: _noop,
          onDelete: _noop,
        ),
        const SizedBox(height: 10),
        AddAccountCard(enabled: true, onTap: _noop),
      ],
    ),
  ),
);
