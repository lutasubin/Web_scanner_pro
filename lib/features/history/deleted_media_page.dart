import 'package:flutter/material.dart';

import '../../core/di/di.dart';
import '../../core/models/media_record.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/media_repository.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/widgets/media_preview.dart';
import '../onboarding/feature_permission_onboarding.dart';

class DeletedMediaPage extends StatefulWidget {
  const DeletedMediaPage({super.key});

  @override
  State<DeletedMediaPage> createState() => _DeletedMediaPageState();
}

class _DeletedMediaPageState extends State<DeletedMediaPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  final List<MediaRecord> _allItems = [];
  bool _loading = false;

  static const _tabs = <String>[
    'Photo',
    'Video',
    'Audio',
    'Voice Note',
    'Documents',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    await _loadMedia();
    if (!mounted) return;
    if (_allItems.isEmpty && services.isRegistered<PreferencesRepository>()) {
      final prefs = services<PreferencesRepository>();
      if (!prefs.value.value.shownStorageDialog) {
        try {
          await prefs.update({'shownStorageDialog': true});
        } catch (_) {}
        if (!mounted) return;
        await showStoragePermissionOnboardingDialog(
          context,
          onAllow: _selectFolder,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (!services.isRegistered<AppPlatform>()) return;
    setState(() => _loading = true);
    try {
      final platform = services<AppPlatform>();
      final statuses = (await platform.readList(
        'listStatuses',
        {'business': false},
      )).map(MediaRecord.fromMap);
      final files = (await platform.readList(
        'listFiles',
      )).map(MediaRecord.fromMap);
      final byId = <String, MediaRecord>{};
      for (final item in [...files, ...statuses]) {
        byId[item.id] = item;
      }
      if (mounted) {
        setState(() {
          _allItems
            ..clear()
            ..addAll(byId.values);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectFolder() async {
    if (!services.isRegistered<AppPlatform>()) return;
    try {
      await services<AppPlatform>().invoke<void>('selectStatusTree', {
        'business': false,
      });
      await _loadMedia();
    } catch (_) {}
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuideStoragePage(onAllowFolder: _selectFolder),
      ),
    );
  }

  List<MediaRecord> _itemsForTab(int index) {
    return _allItems.where((item) {
      final lowerName = item.name.toLowerCase();
      switch (index) {
        case 0: // Photo
          return item.isImage;
        case 1: // Video
          return item.isVideo;
        case 2: // Audio
          return item.isAudio &&
              !lowerName.endsWith('.opus') &&
              !lowerName.contains('ptt-');
        case 3: // Voice Note
          return item.isAudio &&
              (lowerName.endsWith('.opus') || lowerName.contains('ptt-'));
        case 4: // Documents
          return !item.isImage && !item.isVideo && !item.isAudio;
        default:
          return false;
      }
    }).toList();
  }

  void _openItem(List<MediaRecord> list, int index) {
    final target = list[index];
    final repo = services.isRegistered<MediaRepository>()
        ? services<MediaRepository>()
        : null;
    if (target.isImage || target.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MediaViewerPage(
            items: list,
            initialIndex: index,
            onShare: repo != null ? repo.share : (_) async {},
            onOpenExternal: repo != null ? repo.open : (_) async {},
          ),
        ),
      );
    } else {
      repo?.open(target);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F6F8),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        'Deleted Media File',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Guide',
          onPressed: _openGuide,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFF08C567),
            indicatorWeight: 3,
            labelColor: const Color(0xFF1C1F1D),
            unselectedLabelColor: const Color(0xFF8C9690),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (tabIdx) {
                final list = _itemsForTab(tabIdx);
                if (list.isEmpty) {
                  return _EmptyDeletedMediaView(onViewGuide: _openGuide);
                }
                if (tabIdx == 0 || tabIdx == 1) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 160,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                    itemCount: list.length,
                    itemBuilder: (context, idx) {
                      final item = list[idx];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openItem(list, idx),
                        child: MediaPreviewBox(record: item, borderRadius: 12),
                      );
                    },
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = list[idx];
                    return Card(
                      child: ListTile(
                        onTap: () => _openItem(list, idx),
                        leading: SizedBox(
                          width: 44,
                          height: 44,
                          child: MediaPreviewBox(
                            record: item,
                            borderRadius: 8,
                            showVideoBadge: false,
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(item.sizeLabel),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          // Bottom floating bar matching `orig_del_chat_sample.png`
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Material(
              color: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x26000000),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: const Key('deleted-media-use-folder-bar'),
                borderRadius: BorderRadius.circular(16),
                onTap: _selectFolder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 26,
                        color: Color(0xFF1C1F1D),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Tap ‘USE THIS FOLDER’ to recover media messages",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1F1D),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF08C567),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyDeletedMediaView extends StatelessWidget {
  const _EmptyDeletedMediaView({required this.onViewGuide});

  final VoidCallback onViewGuide;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/no_content.webp',
            width: 132,
            height: 132,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            "Looks like WA media folder isn’t authorized yet, or no deleted media files have been detected.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7870),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF08C567),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onViewGuide,
              child: const Text(
                'View the Guide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
