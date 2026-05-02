// lib/features/portfolio/presentation/screens/portfolio_screen.dart
// ═══════════════════════════════════════════════════════════════════
// Public Portfolio — Share your developer profile publicly
// ═══════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';
import 'package:developer_os/features/achievements/presentation/screens/achievements_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// Portfolio Settings Model
// ═══════════════════════════════════════════════════════════════════
class PortfolioSettings {
  final bool isPublic;
  final String username;   // developer_os.web.app/username
  final bool showSkills;
  final bool showProjects;
  final bool showAchievements;
  final bool showStats;
  final bool showGitHub;
  final bool showLinks;
  final String? customBio;
  final String theme; // 'dark', 'light', 'minimal', 'glass'

  const PortfolioSettings({
    this.isPublic = false,
    this.username = '',
    this.showSkills = true,
    this.showProjects = true,
    this.showAchievements = true,
    this.showStats = true,
    this.showGitHub = true,
    this.showLinks = true,
    this.customBio,
    this.theme = 'dark',
  });

  String get publicUrl => 'https://developer_os.web.app/$username';

  factory PortfolioSettings.fromMap(Map<String, dynamic> m) => PortfolioSettings(
    isPublic: m['isPublic'] ?? false,
    username: m['username'] ?? '',
    showSkills: m['showSkills'] ?? true,
    showProjects: m['showProjects'] ?? true,
    showAchievements: m['showAchievements'] ?? true,
    showStats: m['showStats'] ?? true,
    showGitHub: m['showGitHub'] ?? true,
    showLinks: m['showLinks'] ?? true,
    customBio: m['customBio'],
    theme: m['theme'] ?? 'dark',
  );

  Map<String, dynamic> toMap() => {
    'isPublic': isPublic, 'username': username,
    'showSkills': showSkills, 'showProjects': showProjects,
    'showAchievements': showAchievements, 'showStats': showStats,
    'showGitHub': showGitHub, 'showLinks': showLinks,
    'customBio': customBio, 'theme': theme,
  };

  PortfolioSettings copyWith({
    bool? isPublic, String? username, bool? showSkills, bool? showProjects,
    bool? showAchievements, bool? showStats, bool? showGitHub, bool? showLinks,
    String? customBio, String? theme,
  }) => PortfolioSettings(
    isPublic: isPublic ?? this.isPublic, username: username ?? this.username,
    showSkills: showSkills ?? this.showSkills, showProjects: showProjects ?? this.showProjects,
    showAchievements: showAchievements ?? this.showAchievements, showStats: showStats ?? this.showStats,
    showGitHub: showGitHub ?? this.showGitHub, showLinks: showLinks ?? this.showLinks,
    customBio: customBio ?? this.customBio, theme: theme ?? this.theme,
  );
}

// ═══════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════
final portfolioSettingsProvider =
    StateNotifierProvider<PortfolioSettingsNotifier, PortfolioSettings>((ref) {
  return PortfolioSettingsNotifier(ref);
});

class PortfolioSettingsNotifier extends StateNotifier<PortfolioSettings> {
  final Ref _ref;
  PortfolioSettingsNotifier(this._ref) : super(const PortfolioSettings()) { _load(); }

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = doc.data()?['portfolioSettings'];
      if (data != null && mounted) {
        state = PortfolioSettings.fromMap(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
  }

  Future<void> save(PortfolioSettings settings) async {
    state = settings;
    if (_uid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(_uid).set(
      {'portfolioSettings': settings.toMap()},
      SetOptions(merge: true),
    );
    // Also write to public collection if enabled
    if (settings.isPublic && settings.username.isNotEmpty) {
      await _publishPortfolio(settings);
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    if (username.isEmpty || username.length < 3) return false;
    final snap = await FirebaseFirestore.instance
        .collection('public_portfolios').doc(username.toLowerCase()).get();
    if (!snap.exists) return true;
    // Allow if it's the current user's username
    return snap.data()?['uid'] == _uid;
  }

  Future<void> _publishPortfolio(PortfolioSettings settings) async {
    final profile = _ref.read(profileProvider).asData?.value;
    final skills  = _ref.read(skillsProvider).asData?.value ?? [];
    final certs   = _ref.read(certificatesProvider).asData?.value ?? [];
    final links   = _ref.read(linksProvider).asData?.value ?? [];
    final projects = _ref.read(projectsProvider).asData?.value ?? [];
    final unlocked = _ref.read(unlockedAchievementsProvider).asData?.value ?? [];

    if (profile == null) return;

    await FirebaseFirestore.instance
        .collection('public_portfolios')
        .doc(settings.username.toLowerCase())
        .set({
      'uid': _uid,
      'username': settings.username,
      'settings': settings.toMap(),
      'profile': {
        'name': profile.name,
        'bio': settings.customBio ?? profile.bio,
        'specialization': profile.specialization,
        'level': profile.experienceLevel,
        'location': profile.location,
        'website': profile.website,
        'photoURL': profile.photoURL,
        'techSkills': profile.techSkills,
      },
      'skills': settings.showSkills
          ? skills.map((s) => {'name': s.name, 'level': s.proficiency}).toList()
          : [],
      'certs': settings.showSkills
          ? certs.map((c) => {'title': c.title, 'issuer': c.issuer}).toList()
          : [],
      'links': settings.showLinks
          ? links.map((l) => {'type': l.type, 'url': l.url}).toList()
          : [],
      'projects': settings.showProjects
          ? projects.map((p) => {'name': p.name, 'description': p.description}).toList()
          : [],
      'unlockedAchievements': settings.showAchievements
          ? unlocked.map((u) => u.achievementId).toList()
          : [],
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> unpublish() async {
    final username = state.username;
    state = state.copyWith(isPublic: false);
    await FirebaseFirestore.instance.collection('users').doc(_uid)
        .set({'portfolioSettings': state.toMap()}, SetOptions(merge: true));
    if (username.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('public_portfolios').doc(username.toLowerCase()).delete();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Portfolio Screen — Settings + Preview
// ═══════════════════════════════════════════════════════════════════
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _usernameCtrl = TextEditingController();
  bool _checkingUsername = false;
  bool? _usernameAvailable;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final settings = ref.read(portfolioSettingsProvider);
    _usernameCtrl.text = settings.username;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) { setState(() => _usernameAvailable = null); return; }
    setState(() => _checkingUsername = true);
    final available = await ref.read(portfolioSettingsProvider.notifier)
        .checkUsernameAvailable(username);
    if (mounted) setState(() { _usernameAvailable = available; _checkingUsername = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(portfolioSettingsProvider);
    final notifier = ref.read(portfolioSettingsProvider.notifier);

    return SafeArea(
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('// public page', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
              Text('Portfolio', style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                  fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)),
            ]),
            // Live indicator
            if (settings.isPublic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                    color: Colors.green.withOpacity(0.15),
                    border: Border.all(color: Colors.green.withOpacity(0.3))),
                child: Row(children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.green))
                      .animate().then().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2),
                      duration: 800.ms).then().scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 800.ms),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                      fontWeight: FontWeight.w800, color: Colors.green, letterSpacing: 1)),
                ]),
              ),
          ]).animate().fadeIn(),
        ),

        const SizedBox(height: 16),

        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(padding: const EdgeInsets.all(4),
            child: TabBar(controller: _tabCtrl,
              labelColor: isDark ? AppTheme.black : AppTheme.white,
              unselectedLabelColor: isDark ? AppTheme.gray : AppTheme.lightGray,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(10),
                  color: isDark ? AppTheme.white : AppTheme.black),
              labelStyle: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                  fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'SETTINGS'), Tab(text: 'PREVIEW')],
            )),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            // ── Settings Tab ──────────────────────────────────
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // URL field
                GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('developer_os.web.app/', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    Expanded(child: TextField(
                      controller: _usernameCtrl,
                      onChanged: (v) {
                        final clean = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                        if (clean != v) _usernameCtrl.text = clean;
                        _checkUsername(clean);
                      },
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black),
                      decoration: InputDecoration(
                        border: InputBorder.none, isCollapsed: true,
                        hintText: 'your-username',
                        hintStyle: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                        suffixIcon: _checkingUsername
                            ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                            : _usernameAvailable == true
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                            : _usernameAvailable == false
                            ? const Icon(Icons.cancel, color: Colors.red, size: 18)
                            : null,
                      ),
                    )),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    _usernameAvailable == false
                        ? '✗ Username taken — try another'
                        : _usernameAvailable == true
                        ? '✓ Username available!'
                        : 'Letters, numbers, underscore. Min 3 chars.',
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                        color: _usernameAvailable == false ? Colors.red
                            : _usernameAvailable == true ? Colors.green
                            : (isDark ? AppTheme.gray : AppTheme.lightGray)),
                  ),
                ])).animate().fadeIn(),

                const SizedBox(height: 12),

                // Publish toggle
                GlassCard(child: Row(children: [
                  Text(settings.isPublic ? '🌐' : '🔒', style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(settings.isPublic ? 'Portfolio is Public' : 'Portfolio is Private',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                    Text(settings.isPublic
                        ? 'Anyone with the link can view'
                        : 'Only you can see your portfolio',
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  ])),
                  Switch(
                    value: settings.isPublic,
                    activeColor: Colors.green,
                    onChanged: (v) async {
                      final username = _usernameCtrl.text.trim();
                      if (v && username.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Choose a username first',
                              style: TextStyle(fontFamily: 'JetBrainsMono')),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                        return;
                      }
                      if (v && _usernameAvailable == false) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Username not available',
                              style: TextStyle(fontFamily: 'JetBrainsMono')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                        return;
                      }
                      final updated = settings.copyWith(isPublic: v, username: username);
                      await notifier.save(updated);
                      if (!v && mounted) notifier.unpublish();
                    },
                  ),
                ])).animate().fadeIn(delay: 100.ms),

                // Share button
                if (settings.isPublic && settings.username.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Your Portfolio URL', style: TextStyle(fontFamily: 'JetBrainsMono',
                              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                          const SizedBox(height: 4),
                          Text(settings.publicUrl, style: TextStyle(fontFamily: 'JetBrainsMono',
                              fontSize: 13, color: isDark ? AppTheme.white : AppTheme.black)),
                        ])),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: settings.publicUrl));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('URL copied!',
                                  style: TextStyle(fontFamily: 'JetBrainsMono')),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ));
                          },
                          child: Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                                color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)),
                            child: Icon(Icons.copy, size: 16,
                                color: isDark ? AppTheme.silver : AppTheme.gray)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      // Share button
                      GestureDetector(
                        onTap: () => Share.share(
                          'Check out my developer portfolio!\n${settings.publicUrl}',
                          subject: 'My Developer OS Portfolio',
                        ),
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.share, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Text('Share Portfolio', style: TextStyle(fontFamily: 'Syne',
                                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(delay: 150.ms),
                ],

                const SizedBox(height: 16),

                // Section visibility
                _SectionLabel('What to Show', isDark),
                const SizedBox(height: 10),

                GlassCard(child: Column(children: [
                  _VisibilityRow('📁', 'Projects', settings.showProjects, isDark,
                      (v) => notifier.save(settings.copyWith(showProjects: v))),
                  _Divider(isDark),
                  _VisibilityRow('🧠', 'Skills & Certs', settings.showSkills, isDark,
                      (v) => notifier.save(settings.copyWith(showSkills: v))),
                  _Divider(isDark),
                  _VisibilityRow('📊', 'Coding Stats', settings.showStats, isDark,
                      (v) => notifier.save(settings.copyWith(showStats: v))),
                  _Divider(isDark),
                  _VisibilityRow('🏆', 'Achievements', settings.showAchievements, isDark,
                      (v) => notifier.save(settings.copyWith(showAchievements: v))),
                  _Divider(isDark),
                  _VisibilityRow('🔗', 'Social Links', settings.showLinks, isDark,
                      (v) => notifier.save(settings.copyWith(showLinks: v))),
                  _Divider(isDark),
                  _VisibilityRow('📦', 'GitHub Repos', settings.showGitHub, isDark,
                      (v) => notifier.save(settings.copyWith(showGitHub: v))),
                ])).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Theme
                _SectionLabel('Portfolio Theme', isDark),
                const SizedBox(height: 10),

                Row(children: [
                  for (final (t, label, emoji) in [
                    ('dark', 'Dark', '🌙'),
                    ('light', 'Light', '☀️'),
                    ('minimal', 'Minimal', '⬜'),
                    ('glass', 'Glass', '💎'),
                  ])
                    Expanded(child: GestureDetector(
                      onTap: () => notifier.save(settings.copyWith(theme: t)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: settings.theme == t
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                          border: Border.all(color: settings.theme == t
                              ? Colors.transparent
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                        ),
                        child: Column(children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: settings.theme == t
                                  ? (isDark ? AppTheme.black : AppTheme.white)
                                  : (isDark ? AppTheme.gray : AppTheme.lightGray))),
                        ]),
                      ),
                    )),
                ]).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 32),
              ],
            ),

            // ── Preview Tab ───────────────────────────────────
            _PortfolioPreview(settings: settings),
          ]),
        ),
      ]),
    );
  }
}

Widget _SectionLabel(String t, bool isDark) => Padding(
  padding: const EdgeInsets.only(left: 4),
  child: Text(t, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 1.5,
      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
);

Widget _Divider(bool isDark) => Divider(height: 1,
    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07));

Widget _VisibilityRow(String emoji, String title, bool value, bool isDark,
    void Function(bool) onChange) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 14,
          fontWeight: FontWeight.w600, color: isDark ? AppTheme.white : AppTheme.black))),
      Switch(value: value, activeColor: isDark ? AppTheme.white : AppTheme.black,
          onChanged: onChange),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════
// Portfolio Preview — shows what the public page looks like
// ═══════════════════════════════════════════════════════════════════
class _PortfolioPreview extends ConsumerWidget {
  final PortfolioSettings settings;
  const _PortfolioPreview({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = settings.theme != 'light';
    final profile = ref.watch(profileProvider).asData?.value;
    final skills  = ref.watch(skillsProvider).asData?.value ?? [];
    final projects = ref.watch(projectsProvider).asData?.value ?? [];
    final unlocked = ref.watch(unlockedAchievementsProvider).asData?.value ?? [];
    final byId = AchievementsData.byId;

    if (profile == null) {
      return Center(child: CircularProgressIndicator(
          color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2));
    }

    final bg = settings.theme == 'dark'
        ? AppTheme.darkest
        : settings.theme == 'light'
        ? const Color(0xFFF8F9FA)
        : settings.theme == 'minimal'
        ? Colors.black
        : const Color(0xFF0D0D1A);

    return Container(
      color: bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            decoration: settings.theme == 'glass'
                ? BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [const Color(0xFF1a1a3e), const Color(0xFF4c1d95)]))
                : null,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar
              if (profile.photoURL != null)
                CircleAvatar(radius: 40, backgroundImage: NetworkImage(profile.photoURL!))
              else
                CircleAvatar(radius: 40, backgroundColor: Colors.purple.withOpacity(0.3),
                  child: Text(profile.name?.isNotEmpty == true ? profile.name![0] : '?',
                      style: const TextStyle(fontFamily: 'Syne', fontSize: 32,
                          fontWeight: FontWeight.w800, color: Colors.white))),
              const SizedBox(height: 16),
              Text(profile.name ?? 'Developer', style: const TextStyle(fontFamily: 'Syne',
                  fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(profile.specialization ?? 'Developer', style: TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: 14,
                  color: Colors.white.withOpacity(0.7))),
              if (profile.location != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(profile.location!, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                      color: Colors.white.withOpacity(0.6))),
                ]),
              ],
              if (profile.bio != null) ...[
                const SizedBox(height: 16),
                Text(settings.customBio ?? profile.bio!, style: TextStyle(fontFamily: 'JetBrainsMono',
                    fontSize: 13, height: 1.6, color: Colors.white.withOpacity(0.8))),
              ],
              if (profile.website != null) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse(profile.website!)),
                  child: Text(profile.website!, style: const TextStyle(fontFamily: 'JetBrainsMono',
                      fontSize: 12, color: Color(0xFF60A5FA),
                      decoration: TextDecoration.underline)),
                ),
              ],
            ]),
          ),

          // Tech stack
          if (profile.techSkills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tech Stack', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                    fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: profile.techSkills.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                        color: Colors.purple.withOpacity(0.15),
                        border: Border.all(color: Colors.purple.withOpacity(0.3))),
                    child: Text(t, style: const TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 12, color: Colors.purple)),
                  )).toList()),
              ]),
            ),

          // Skills
          if (settings.showSkills && skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Skills', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                    fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 10),
                ...skills.take(20).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(s.name, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                          color: isDark ? Colors.white : Colors.black)),
                      Text('${s.proficiency}%', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black54)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.proficiency / 100, minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                      )),
                  ]),
                )),
              ]),
            ),

          // Achievements
          if (settings.showAchievements && unlocked.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Achievements', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                    fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 10),
                Wrap(spacing: 5, runSpacing: 5,
                  children: unlocked.take(20).map((u) {
                    final a = byId[u.achievementId];
                    if (a == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                          color: Colors.amber.withOpacity(0.1),
                          border: Border.all(color: Colors.amber.withOpacity(0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(a.title, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                            color: isDark ? Colors.amber : Colors.amber.shade800,
                            fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }).toList()),
              ]),
            ),


          // Projects Section
          if (settings.showProjects && projects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projects',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // عرض المشاريع بشكل قائمة بطاقات
                  Column(
                    children: projects.take(50).map((p) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // السطر الأول: الاسم والحالة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                // Badge للحالة (Active, Archived, etc.)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.status == 'active' 
                                        ? Colors.green.withOpacity(0.1) 
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: p.status == 'active' ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // الوصف (Description)
                            if (p.description.isNotEmpty)
                              Text(
                                p.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                            const SizedBox(height: 12),

                            // المهارات (Tech Stack)
                            if (p.techStack.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: p.techStack.map((tech) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tech,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'JetBrainsMono',
                                      color: isDark ? Colors.grey.shade300 : Colors.black87,
                                    ),
                                  ),
                                )).toList(),
                              ),

                            // لينك الجيت هب (GitHub Link)
                            if ((p.githubUrl ?? '').isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, thickness: 0.5),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () {
                                  // هنا ممكن تستخدم url_launcher لفتح اللينك
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link, size: 14, color: Colors.blue.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      'GitHub Repository',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade400,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 40),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Text('Built with Developer OS',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                    color: isDark ? Colors.white24 : Colors.black26)),
          ),
        ]),
      ),
    );
  }
}