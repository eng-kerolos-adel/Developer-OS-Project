import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/animated_background.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final authState = ref.read(authStateProvider).asData?.value;
    final box = Hive.box('developer_os_prefs');
    final hasSeenOnboarding = box.get('hasSeenOnboarding', defaultValue: false) as bool;

    if (authState != null) {
      context.go(RouteConstants.home);
    } else if (!hasSeenOnboarding) {
      context.go(RouteConstants.onboarding);
    } else {
      context.go(RouteConstants.login);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? AppTheme.white : AppTheme.black)
                            .withOpacity(0.2 + _pulseController.value * 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.05 + _pulseController.value * 0.1),
                          blurRadius: 30 + _pulseController.value * 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                  ),
                  child: Center(
                    child: Text(
                      '</>', 
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // App name
              Text(
                'DEVELOPER OS',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.white : AppTheme.black,
                  letterSpacing: 6,
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              Text(
                'YOUR COMMAND CENTER',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppTheme.silver : AppTheme.gray,
                  letterSpacing: 4,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 64),

              // Loading indicator
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppTheme.white : AppTheme.black,
                  ),
                  minHeight: 1,
                ),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
