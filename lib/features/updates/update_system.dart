// lib/features/updates/update_system.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/notifications/providers/notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════
// Version Info Model
// ═══════════════════════════════════════════════════════════════════
class VersionInfo {
  final String version;
  final int buildNumber;
  final List<ChangelogEntry> changelog;
  final bool mandatory;
  final String? minSupportedVersion;
  final String? storeUrl;
  final DateTime releaseDate;
  final String releaseNotes;

  const VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.changelog,
    this.mandatory = false,
    this.minSupportedVersion,
    this.storeUrl,
    required this.releaseDate,
    this.releaseNotes = '',
  });

  bool isNewerThan(String currentVersion) =>
      _compare(version, currentVersion) > 0;

  bool isMandatoryFor(String currentVersion) {
    if (!mandatory) return false;
    if (minSupportedVersion == null) return true;
    return _compare(currentVersion, minSupportedVersion!) < 0;
  }

  static int _compare(String a, String b) {
    final av = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bv = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final ai = av.length > i ? av[i] : 0;
      final bi = bv.length > i ? bv[i] : 0;
      if (ai > bi) return 1;
      if (ai < bi) return -1;
    }
    return 0;
  }

  factory VersionInfo.fromMap(Map<String, dynamic> m) => VersionInfo(
    version: m['version'] ?? '1.0.0',
    buildNumber: m['buildNumber'] ?? 1,
    mandatory: m['mandatory'] ?? false,
    minSupportedVersion: m['minSupportedVersion'],
    storeUrl: m['storeUrl'],
    releaseDate: m['releaseDate'] is int
        ? DateTime.fromMillisecondsSinceEpoch(m['releaseDate'])
        : DateTime.now(),
    releaseNotes: m['releaseNotes'] ?? '',
    changelog: (m['changelog'] as List? ?? [])
        .map((e) => ChangelogEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

class ChangelogEntry {
  final ChangeType type;
  final String text;
  final bool isHighlight;

  const ChangelogEntry({required this.type, required this.text, this.isHighlight = false});

  factory ChangelogEntry.fromMap(Map<String, dynamic> m) => ChangelogEntry(
    type: ChangeType.values.firstWhere(
      (t) => t.name == m['type'],
      orElse: () => ChangeType.improvement,
    ),
    text: m['text'] ?? '',
    isHighlight: m['highlight'] ?? false,
  );
}

enum ChangeType { feature, improvement, bugfix, security, breaking }

extension ChangeTypeX on ChangeType {
  String get emoji {
    switch (this) {
      case ChangeType.feature:     return '✨';
      case ChangeType.improvement: return '⚡';
      case ChangeType.bugfix:      return '🐛';
      case ChangeType.security:    return '🔐';
      case ChangeType.breaking:    return '⚠️';
    }
  }
  String get label {
    switch (this) {
      case ChangeType.feature:     return 'New';
      case ChangeType.improvement: return 'Improved';
      case ChangeType.bugfix:      return 'Fixed';
      case ChangeType.security:    return 'Security';
      case ChangeType.breaking:    return 'Changed';
    }
  }
  Color get color {
    switch (this) {
      case ChangeType.feature:     return Colors.blue;
      case ChangeType.improvement: return Colors.purple;
      case ChangeType.bugfix:      return Colors.green;
      case ChangeType.security:    return Colors.orange;
      case ChangeType.breaking:    return Colors.red;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// State
// ═══════════════════════════════════════════════════════════════════
class UpdateState {
  final bool isLoading;
  final VersionInfo? latest;
  final String currentVersion;
  final int currentBuild;
  final bool dismissed;
  final String? dismissedVersion; // ✅ FIX: نحفظ الـ version اللي اتعمل dismiss ليها

  const UpdateState({
    this.isLoading = false,
    this.latest,
    this.currentVersion = '1.0.0',
    this.currentBuild = 2,
    this.dismissed = false,
    this.dismissedVersion,
  });

  // ✅ FIX: hasUpdate بيتحقق إن الـ version الجديدة مش نفس اللي اتعمل dismiss ليها
  bool get hasUpdate {
    if (latest == null) return false;
    if (!latest!.isNewerThan(currentVersion)) return false;
    if (dismissedVersion == latest!.version) return false; // تم الـ dismiss لهذا الإصدار
    return true;
  }

  bool get isMandatory =>
      latest != null && latest!.isMandatoryFor(currentVersion);

  UpdateState copyWith({
    bool? isLoading,
    VersionInfo? latest,
    String? currentVersion,
    int? currentBuild,
    bool? dismissed,
    String? dismissedVersion,
  }) => UpdateState(
    isLoading: isLoading ?? this.isLoading,
    latest: latest ?? this.latest,
    currentVersion: currentVersion ?? this.currentVersion,
    currentBuild: currentBuild ?? this.currentBuild,
    dismissed: dismissed ?? this.dismissed,
    dismissedVersion: dismissedVersion ?? this.dismissedVersion,
  );
}

// ═══════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════
final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier(ref);
});

class UpdateNotifier extends StateNotifier<UpdateState> {
  final Ref _ref;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  String? _lastNotifiedVersion;

  UpdateNotifier(this._ref) : super(const UpdateState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        state = state.copyWith(
          currentVersion: info.version,
          currentBuild: int.tryParse(info.buildNumber) ?? 1,
        );
      }
    } catch (_) {}

    // 2. ننتظر 3 ثواني بعد فتح التطبيق
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // 3. نفتح Stream مباشر مع Firestore
    _listenToFirestore();
  }

  void _listenToFirestore() {
    state = state.copyWith(isLoading: true);

    _sub = FirebaseFirestore.instance
        .collection('app_config')
        .doc('latest_version')
        .snapshots()
        .listen(
      (doc) async {
        if (!mounted) return;

        if (!doc.exists || doc.data() == null) {
          state = state.copyWith(isLoading: false);
          return;
        }

        final latest = VersionInfo.fromMap(doc.data()!);

        // ✅ FIX: نحدث الـ state بدون reset الـ dismissedVersion
        // إلا لو الـ version الجديدة مختلفة عن اللي اتعمل dismiss ليها
        final newDismissedVersion = state.dismissedVersion == latest.version
            ? state.dismissedVersion  // نفس الـ version → keep dismissed
            : null;                   // إصدار جديد → reset dismissed

        state = state.copyWith(
          isLoading: false,
          latest: latest,
          dismissedVersion: newDismissedVersion,
        );

        // ✅ FIX: بنبعت الإشعار مرة واحدة فقط لكل إصدار جديد
        if (latest.isNewerThan(state.currentVersion) &&
            _lastNotifiedVersion != latest.version) {
          _lastNotifiedVersion = latest.version;

          final features = latest.changelog
              .where((e) => e.type == ChangeType.feature)
              .map((e) => e.text)
              .toList();

          try {
            await _ref.read(notifControllerProvider).newVersion(
                latest.version, features);
          } catch (_) {}
        }
      },
      onError: (e) {
        if (mounted) state = state.copyWith(isLoading: false);
      },
    );
  }

  // ✅ FIX: dismiss يحفظ الـ version عشان نعرف ما نعرضهاش تاني
  void dismiss() {
    state = state.copyWith(
      dismissed: true,
      dismissedVersion: state.latest?.version,
    );
  }

  Future<void> openStore() async {
    final url = state.latest?.storeUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> forceCheck() async {
    _sub?.cancel();
    _listenToFirestore();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Update Banner Widget
// ═══════════════════════════════════════════════════════════════════
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider);
    if (!update.hasUpdate) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = update.latest!;
    final topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => _showUpdateSheet(context, ref),
      child: Container(
        margin: EdgeInsets.fromLTRB(16, topPadding + 20, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1a1a3e), const Color(0xFF2d1b69)]
                : [const Color(0xFFe8f0fe), const Color(0xFFf3e8ff)],
          ),
          border: Border.all(
              color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.15)),
            child: const Center(child: Text('🚀', style: TextStyle(fontSize: 20))),
          ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.easeOutBack),

          const SizedBox(width: 12),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                // 1. رقم الإصدار ثابت في الحالتين
                Text(
                  'v${info.version}',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(width: 8),

                if (update.isMandatory)
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.red.withOpacity(0.15),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'REQUIRED',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else
                    Text(
                        'Available',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.blue.shade900,
                        ),
                      ),
              ],
            ),
            if (info.releaseNotes.isNotEmpty)
              Text(info.releaseNotes,
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade700),
                  overflow: TextOverflow.ellipsis),
          ])),

          const SizedBox(width: 8),

          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
            child: const Text("What's new",
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                    fontWeight: FontWeight.w700, color: Colors.white))),

          if (!update.isMandatory) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => ref.read(updateProvider.notifier).dismiss(),
              child: Icon(Icons.close, size: 16,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade400)),
          ],
        ]),
      ),
    ).animate()
        .slideY(begin: -0.5, end: 0, duration: 400.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 300.ms);
  }

  void _showUpdateSheet(BuildContext context, WidgetRef ref) {
    final update = ref.read(updateProvider);
    if (update.latest == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateSheet(info: update.latest!, update: update, isDark: isDark, ref: ref),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Update Sheet
// ═══════════════════════════════════════════════════════════════════
class _UpdateSheet extends StatelessWidget {
  final VersionInfo info;
  final UpdateState update;
  final bool isDark;
  final WidgetRef ref;

  const _UpdateSheet({required this.info, required this.update, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    final features     = info.changelog.where((e) => e.type == ChangeType.feature).toList();
    final improvements = info.changelog.where((e) => e.type == ChangeType.improvement).toList();
    final bugfixes     = info.changelog.where((e) => e.type == ChangeType.bugfix).toList();
    final security     = info.changelog.where((e) => e.type == ChangeType.security).toList();
    final highlights   = info.changelog.where((e) => e.isHighlight).toList();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF141414) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15)))),

        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // App icon + version
              Row(children: [
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF1a1a3e), Color(0xFF2d1b69)])),
                  child: const Center(child: Text('🚀', style: TextStyle(fontSize: 28)))),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Developer OS', style: TextStyle(fontFamily: 'Syne', fontSize: 18,
                      fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                  Text('v${info.version} · ${_fmtDate(info.releaseDate)}',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  if (update.isMandatory)
                    Container(margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
                          color: Colors.red.withOpacity(0.15), border: Border.all(color: Colors.red.withOpacity(0.4))),
                      child: const Text('REQUIRED UPDATE',
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                              fontWeight: FontWeight.w800, color: Colors.red, letterSpacing: 1))),
                ]),
              ]),

              const SizedBox(height: 20),

              if (highlights.isNotEmpty) ...[
                _section('⭐ Highlights', isDark),
                const SizedBox(height: 10),
                ...highlights.map((e) => _HighlightCard(entry: e, isDark: isDark)),
                const SizedBox(height: 16),
              ],
              if (features.isNotEmpty) ...[
                _section('✨ New Features', isDark, color: Colors.blue),
                const SizedBox(height: 8),
                ...features.map((e) => _Row(entry: e, isDark: isDark)),
                const SizedBox(height: 16),
              ],
              if (improvements.isNotEmpty) ...[
                _section('⚡ Improvements', isDark, color: Colors.purple),
                const SizedBox(height: 8),
                ...improvements.map((e) => _Row(entry: e, isDark: isDark)),
                const SizedBox(height: 16),
              ],
              if (bugfixes.isNotEmpty) ...[
                _section('🐛 Bug Fixes', isDark, color: Colors.green),
                const SizedBox(height: 8),
                ...bugfixes.map((e) => _Row(entry: e, isDark: isDark)),
                const SizedBox(height: 16),
              ],
              if (security.isNotEmpty) ...[
                _section('🔐 Security', isDark, color: Colors.orange),
                const SizedBox(height: 8),
                ...security.map((e) => _Row(entry: e, isDark: isDark)),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
            ]),
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(children: [
            GestureDetector(
              onTap: () => ref.read(updateProvider.notifier).openStore(),
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🚀', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  const Text('Update Now', style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                      fontWeight: FontWeight.w800, color: Colors.white)),
                ])),
            ),
            if (!update.isMandatory) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  ref.read(updateProvider.notifier).dismiss();
                  Navigator.pop(context);
                },
                child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                  child: Center(child: Text('Remind Me Later',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.silver : AppTheme.gray)))),
              ),
            ],
            if (update.isMandatory) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, size: 13, color: Colors.red),
                const SizedBox(width: 5),
                Text('This update is required to continue', style: TextStyle(fontFamily: 'JetBrainsMono',
                    fontSize: 11, color: Colors.red.withOpacity(0.8))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _section(String text, bool isDark, {Color? color}) => Row(children: [
    if (color != null) Container(width: 3, height: 16, margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color)),
    Text(text, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black)),
  ]);

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _HighlightCard extends StatelessWidget {
  final ChangelogEntry entry;
  final bool isDark;
  const _HighlightCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [
          entry.type.color.withOpacity(isDark ? 0.15 : 0.08),
          entry.type.color.withOpacity(isDark ? 0.08 : 0.04),
        ]),
        border: Border.all(color: entry.type.color.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.type.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                color: entry.type.color.withOpacity(0.15)),
            child: Text(entry.type.label.toUpperCase(),
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8,
                    fontWeight: FontWeight.w800, color: entry.type.color, letterSpacing: 1))),
          const SizedBox(height: 4),
          Text(entry.text, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
              height: 1.5, color: isDark ? AppTheme.silver : AppTheme.gray)),
        ])),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final ChangelogEntry entry;
  final bool isDark;
  const _Row({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(entry.type.emoji, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 8),
      Expanded(child: Text(entry.text, style: TextStyle(fontFamily: 'JetBrainsMono',
          fontSize: 12, height: 1.5, color: isDark ? AppTheme.silver : AppTheme.gray))),
    ]),
  );
}