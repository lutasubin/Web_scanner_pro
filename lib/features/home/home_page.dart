import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/router/app_routes.dart';
import '../sessions/web_session.dart';
import 'feature_card.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.find<HomeController>();
    controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.load();
  }

  Future<void> _openAccounts() async {
    await Get.toNamed<void>(AppRoutes.sessions);
    await controller.load();
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => HomeDashboard(
      activeSession: controller.activeSession,
      loading: controller.busy.value,
      error: controller.error.value,
      onSettings: () => Get.toNamed<void>(AppRoutes.settings),
      onAccount: controller.openActive,
      onAccountManagement: _openAccounts,
      onDualApp: controller.openActive,
      onDeletedMessages: () => Get.toNamed<void>(AppRoutes.history),
      onDownloads: () => Get.toNamed<void>(AppRoutes.files),
      onStatusSaver: () => Get.toNamed<void>(AppRoutes.statuses),
      onDirectChat: () => Get.toNamed<void>(AppRoutes.directChat),
      onHowToUse: () => Get.toNamed<void>(AppRoutes.howToUse),
    ),
  );
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.activeSession,
    required this.loading,
    required this.error,
    required this.onSettings,
    required this.onAccount,
    required this.onAccountManagement,
    required this.onDualApp,
    required this.onDeletedMessages,
    required this.onDownloads,
    required this.onStatusSaver,
    required this.onDirectChat,
    required this.onHowToUse,
  });

  final WebSession? activeSession;
  final bool loading;
  final String error;
  final VoidCallback onSettings;
  final VoidCallback onAccount;
  final VoidCallback onAccountManagement;
  final VoidCallback onDualApp;
  final VoidCallback onDeletedMessages;
  final VoidCallback onDownloads;
  final VoidCallback onStatusSaver;
  final VoidCallback onDirectChat;
  final VoidCallback onHowToUse;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                sliver: SliverList.list(
                  children: [
                    _HomeHeader(onSettings: onSettings),
                    if (loading) ...[
                      const SizedBox(height: 4),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (activeSession case final session?) ...[
                      _AccountPreviewCard(name: session.name, onTap: onAccount),
                      const SizedBox(height: 13),
                      _AccountManagementCard(onTap: onAccountManagement),
                      const SizedBox(height: 17),
                    ],
                    _DualAppBanner(onTap: onDualApp),
                    const SizedBox(height: 17),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 104,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                          ),
                      children: [
                        FeatureCard(
                          key: const Key('deleted-messages'),
                          icon: Icons.delete_outline_rounded,
                          title: 'Deleted\nMessages',
                          onTap: onDeletedMessages,
                        ),
                        FeatureCard(
                          key: const Key('downloads'),
                          icon: Icons.file_download_outlined,
                          title: 'Downloads',
                          onTap: onDownloads,
                        ),
                        FeatureCard(
                          key: const Key('status-saver'),
                          icon: Icons.downloading_outlined,
                          title: 'Status Saver',
                          onTap: onStatusSaver,
                        ),
                        FeatureCard(
                          key: const Key('direct-chat'),
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Direct Chat',
                          onTap: onDirectChat,
                        ),
                        FeatureCard(
                          key: const Key('how-to-use'),
                          icon: Icons.help_outline_rounded,
                          title: 'How To Use',
                          onTap: onHowToUse,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Web Scanner',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        IconButton(
          key: const Key('settings'),
          tooltip: 'Settings',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined, size: 25),
        ),
      ],
    ),
  );
}

class _AccountPreviewCard extends StatelessWidget {
  const _AccountPreviewCard({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: 96,
      height: 96,
      child: Card(
        child: InkWell(
          key: const Key('active-account'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ProfileIcon(),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AccountManagementCard extends StatelessWidget {
  const _AccountManagementCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Card(
      child: InkWell(
        key: const Key('account-management'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(Icons.group_outlined, size: 25),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Account Management',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 26),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DualAppBanner extends StatelessWidget {
  const _DualAppBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF08C567),
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const Key('dual-app'),
      onTap: onTap,
      child: SizedBox(
        height: 94,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Dual App',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.black,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'WA & Business',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF009C55),
                size: 72,
              ),
              const SizedBox(width: 13),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 27,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProfileIcon extends StatelessWidget {
  const ProfileIcon({super.key, this.filled = false});

  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: filled ? const Color(0xFF08C567) : const Color(0xFFE7FAF0),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Icon(
      Icons.person_outline_rounded,
      color: filled ? Colors.white : const Color(0xFF08C567),
      size: 23,
    ),
  );
}
