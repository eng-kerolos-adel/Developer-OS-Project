import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/core/providers/theme_provider.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';
import 'package:developer_os/features/github/presentation/screens/github_connect_screen.dart';
import 'package:developer_os/features/ai/services/ai_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../auth/services/biometric_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final githubToken = ref.watch(githubTokenProvider);
    final aiKey = ref.watch(aiApiKeyProvider);
    final githubStats = ref.watch(githubStatsProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('// preferences',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Settings',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ],
              ).animate().fadeIn(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Appearance ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('APPEARANCE', isDark),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Row(children: [
                      Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                          color: isDark ? AppTheme.white : AppTheme.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Theme',
                                  style: TextStyle(
                                      fontFamily: 'Syne',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.white
                                          : AppTheme.black)),
                              Text(isDark ? 'Dark Mode' : 'Light Mode',
                                  style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: isDark
                                          ? AppTheme.gray
                                          : AppTheme.lightGray)),
                            ]),
                      ),
                      Switch(
                        value: isDark,
                        activeColor: isDark ? AppTheme.white : AppTheme.black,
                        onChanged: (_) => ref
                            .read(themeModeProvider.notifier)
                            .toggleTheme(),
                      ),
                    ]),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Security & App Lock ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('SECURITY', isDark),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero, // عشان يتماشى مع الـ GlassCard padding
                      leading: Icon(Icons.lock_outline_rounded,
                          size: 22,
                          color: isDark ? AppTheme.white : AppTheme.black),
                      title: Text('Privacy & App Lock',
                          style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black)),
                      subtitle: Text('Manage fingerprint and PIN lock',
                          style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray),
                      onTap: () {
                        // لو شغال بـ GoRouter (وده الأفضل بما إنك مستدعيه فوق)
                        // context.push('/settings/security');
                        
                        // أو لو لسه ما عملتش Route ليها في GoRouter استخدم الـ Navigator العادي:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── GitHub ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('GITHUB INTEGRATION', isDark),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(children: [
                      Row(children: [
                        FaIcon(FontAwesomeIcons.github,
                            size: 20,
                            color: isDark ? AppTheme.white : AppTheme.black),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GitHub Account',
                                    style: TextStyle(
                                        fontFamily: 'Syne',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppTheme.white
                                            : AppTheme.black)),
                                Text(
                                    githubToken != null
                                        ? githubStats.when(
                                            data: (s) =>
                                                s != null ? '@${s.username}' : 'Connected',
                                            loading: () => 'Loading...',
                                            error: (_, __) => 'Connected',
                                          )
                                        : 'Not connected',
                                    style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 11,
                                        color: githubToken != null
                                            ? Colors.green
                                            : (isDark
                                                ? AppTheme.gray
                                                : AppTheme.lightGray))),
                              ]),
                        ),
                        if (githubToken != null)
                          GestureDetector(
                            onTap: () => _confirmDisconnectGitHub(context, isDark),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.red.withOpacity(0.1),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text('Disconnect',
                                  style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: Colors.red)),
                            ),
                          )
                        else
                          GlassButton(
                            label: 'Connect',
                            width: 110,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const GitHubConnectScreen()),
                              );
                              if (result == true) {
                                ref.invalidate(githubStatsProvider);
                              }
                            },
                          ),
                      ]),
                      if (githubToken != null) ...[
                        const SizedBox(height: 12),
                        Divider(
                            color: (isDark ? AppTheme.white : AppTheme.black)
                                .withOpacity(0.1)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.info_outline,
                              size: 14,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'When you create a new project, a GitHub repo will be auto-created.',
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  color: isDark
                                      ? AppTheme.gray
                                      : AppTheme.lightGray),
                            ),
                          ),
                        ]),
                      ],
                    ]),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── AI ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('AI ASSISTANT (GEMINI)', isDark),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(children: [
                      Row(children: [
                        Text('✨',
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Google Gemini API Key',
                                    style: TextStyle(
                                        fontFamily: 'Syne',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppTheme.white
                                            : AppTheme.black)),
                                Text(
                                    aiKey != null
                                        ? '✓ Key configured'
                                        : 'Not configured',
                                    style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 11,
                                        color: aiKey != null
                                            ? Colors.green
                                            : (isDark
                                                ? AppTheme.gray
                                                : AppTheme.lightGray))),
                              ]),
                        ),
                        if (aiKey != null)
                          GestureDetector(
                            onTap: () =>
                                ref.read(aiApiKeyProvider.notifier).clearKey(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.red.withOpacity(0.1),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Text('Remove',
                                  style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: Colors.red)),
                            ),
                          )
                        else
                          GlassButton(
                            label: 'Add Key',
                            width: 110,
                            onPressed: () => _showAddAIKey(context, isDark),
                          ),
                      ]),
                      if (aiKey == null) ...[
                        const SizedBox(height: 12),
                        Divider(
                            color: (isDark ? AppTheme.white : AppTheme.black)
                                .withOpacity(0.1)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.info_outline,
                              size: 14,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Get your FREE key at aistudio.google.com',
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  color: isDark
                                      ? AppTheme.gray
                                      : AppTheme.lightGray),
                            ),
                          ),
                        ]),
                      ],
                    ]),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Account ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('ACCOUNT', isDark),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Row(children: [
                      Icon(Icons.logout,
                          size: 20,
                          color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sign Out',
                                  style: TextStyle(
                                      fontFamily: 'Syne',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red)),
                              Text('Sign out from Developer OS',
                                  style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: isDark
                                          ? AppTheme.gray
                                          : AppTheme.lightGray)),
                            ]),
                      ),
                      GestureDetector(
                        onTap: () => _confirmSignOut(context, isDark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.withOpacity(0.1),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text('Sign Out',
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  color: Colors.red)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showAddAIKey(BuildContext context, bool isDark) {
    final keyCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.2)))),
              const SizedBox(height: 20),
              Text('Add Google Gemini API Key',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 8),
              Text(
                  'Get your FREE key at aistudio.google.com → Get API Key',
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
              const SizedBox(height: 16),
              GlassTextField(
                controller: keyCtrl,
                hintText: 'AIzaSy-xxxxxxxxxxxxxxxxxxxx',
                obscureText: true,
                prefixIcon: Icon(Icons.key,
                    size: 16,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: Colors.red)),
              ],
              const SizedBox(height: 16),
              GlassButton(
                label: loading ? 'Validating...' : 'Save Key',
                isLoading: loading,
                onPressed: () async {
                  if (keyCtrl.text.trim().isEmpty) return;
                  setS(() {
                    loading = true;
                    error = null;
                  });
                  final success = await ref
                      .read(aiApiKeyProvider.notifier)
                      .saveKey(keyCtrl.text.trim());
                  setS(() => loading = false);
                  if (success) {
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    setS(() => error = 'Invalid key. Please check and try again.');
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  void _confirmDisconnectGitHub(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
        title: Text('Disconnect GitHub',
            style: TextStyle(
                fontFamily: 'Syne',
                color: isDark ? AppTheme.white : AppTheme.black)),
        content: Text('Are you sure? Auto-repo creation will stop.',
            style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: isDark ? AppTheme.silver : AppTheme.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(githubTokenProvider.notifier).clearToken();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Disconnect',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( 
        backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
        title: Text('Sign Out',
            style: TextStyle(
                fontFamily: 'Syne',
                color: isDark ? AppTheme.white : AppTheme.black)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: isDark ? AppTheme.silver : AppTheme.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), 
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                await ref.read(appLockProvider.notifier).resetAll();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) context.go(RouteConstants.login);
              },
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.gray : AppTheme.lightGray,
            letterSpacing: 2));
  }
}