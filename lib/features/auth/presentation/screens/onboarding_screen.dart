// lib/features/auth/presentation/screens/onboarding_screen.dart
// ═══════════════════════════════════════════════════════════════════
// Professional 5-Step Onboarding
// ═══════════════════════════════════════════════════════════════════
// Package needed: hive_flutter (already in pubspec)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/core/constants/route_constants.dart';
import 'package:developer_os/core/services/monitoring_service.dart';
import 'package:go_router/go_router.dart';
import 'package:developer_os/shared/widgets/animated_background.dart';

// ═══════════════════════════════════════════════════════════════════
// Onboarding Data
// ═══════════════════════════════════════════════════════════════════
class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color accentColor;
  final List<Color> gradientColors;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.accentColor,
    required this.gradientColors,
  });
}

const _pages = [
  _OnboardingPage(
    emoji: '💻',
    title: 'Your Developer\nCommand Center',
    subtitle: 'Everything a developer needs in one powerful app.',
    bullets: [
      'Manage all your projects in one place',
      'Track your coding time & streaks',
      'Journal, learn, and grow every day',
    ],
    accentColor: Color(0xFF7C3AED),
    gradientColors: [Color(0xFF1a1a3e), Color(0xFF4c1d95)],
  ),
  _OnboardingPage(
    emoji: '📁',
    title: 'Projects &\nGitHub Sync',
    subtitle: 'Connect GitHub and manage every project from one screen.',
    bullets: [
      'Auto-import all your GitHub repos',
      'Kanban board, timeline, and tasks',
      'AI-generated roadmaps & README files',
    ],
    accentColor: Color(0xFF2563EB),
    gradientColors: [Color(0xFF0f172a), Color(0xFF1e3a5f)],
  ),
  _OnboardingPage(
    emoji: '🔥',
    title: 'Streaks &\nAnalytics',
    subtitle: 'Build coding habits that last with daily tracking.',
    bullets: [
      'GitHub-style activity heatmap',
      'Pomodoro timer linked to projects',
      'Level up with XP and achievements',
    ],
    accentColor: Color(0xFFEF4444),
    gradientColors: [Color(0xFF1c0a00), Color(0xFF7f1d1d)],
  ),
  _OnboardingPage(
    emoji: '🤖',
    title: 'AI-Powered\nFeatures',
    subtitle: 'Let Gemini AI handle the boring parts so you focus on building.',
    bullets: [
      'Generate project details from just a name',
      'Write your developer bio automatically',
      'Create professional README in seconds',
    ],
    accentColor: Color(0xFF059669),
    gradientColors: [Color(0xFF022c22), Color(0xFF064e3b)],
  ),
  _OnboardingPage(
    emoji: '🚀',
    title: 'Ready to\nLevel Up?',
    subtitle: 'Join developers who track their growth with Developer OS.',
    bullets: [
      'Start your first project today',
      'Set a daily coding goal',
      'Unlock your first achievement',
    ],
    accentColor: Color(0xFFF59E0B),
    gradientColors: [Color(0xFF1c1400), Color(0xFF78350f)],
  ),
];

// ═══════════════════════════════════════════════════════════════════
// Check if onboarding was shown before
// ═══════════════════════════════════════════════════════════════════
bool hasSeenOnboarding() {
  final box = Hive.box('developer_os_prefs');
  return box.get('onboarding_complete', defaultValue: false);
}

Future<void> markOnboardingComplete() async {
  final box = Hive.box('developer_os_prefs');
  await box.put('onboarding_complete', true);
}

// ═══════════════════════════════════════════════════════════════════
// Onboarding Screen
// ═══════════════════════════════════════════════════════════════════
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  late AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    MonitoringService.logOnboardingStep(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await markOnboardingComplete();
    MonitoringService.logOnboardingComplete();
    if (mounted) context.go(RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedBackground(
        // duration: const Duration(milliseconds: 500),
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: page.gradientColors,
        //   ),
        // ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress dots
                    Row(
                      children: List.generate(_pages.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: active ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: active
                                ? page.accentColor
                                : Colors.white.withOpacity(0.3),
                          ),
                        );
                      }),
                    ),
                    // Skip button
                    if (!isLast)
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Pages ────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    MonitoringService.logOnboardingStep(i);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, i) =>
                      _OnboardingPageWidget(page: _pages[i]),
                ),
              ),

              // ── Bottom ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  children: [
                    // CTA button
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: page.accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: page.accentColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? "Let's Start! 🚀" : 'Continue',
                              style: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),

                    if (isLast) ...[
                      const SizedBox(height: 14),
                      Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single page widget ──────────────────────────────────────────
class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji hero
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page.accentColor.withOpacity(0.2),
                border: Border.all(
                    color: page.accentColor.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(page.emoji,
                    style: const TextStyle(fontSize: 56)),
              ),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
          ),

          const SizedBox(height: 36),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withOpacity(0.65),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),

          // Bullets
          ...page.bullets.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 12, top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: page.accentColor.withOpacity(0.25),
                      border: Border.all(
                          color: page.accentColor.withOpacity(0.5)),
                    ),
                    child: Icon(Icons.check,
                        size: 13, color: page.accentColor),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 300 + e.key * 80)),
          ),
        ],
      ),
    );
  }
}

// needed import
