import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/domain/models/developer_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '// system_information',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                        ),
                      ),
                      Text(
                        'Application',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _IconBtn(
                        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _IconBtn(
                        icon: Icons.logout_outlined,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (context.mounted) context.go(RouteConstants.login);
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/kerolos.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(25),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded( 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Developed by',
                                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                              const SizedBox(height: 2),
                              Text('Kerolos Adel',
                                  style: TextStyle(fontFamily: 'Syne', fontSize: 25, fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)),
                              const SizedBox(height: 12),
                              Text(
                                'I am a passionate Full-Stack Developer and UI/UX Designer with a focus on building high-performance, cinematic digital experiences. '
                                'While my core expertise lies in Frontend development, I have a deep understanding of Flutter for cross-platform mobile apps and Backend systems to ensure seamless data integration.'
                                'I love bridging the gap between complex logic and beautiful design, creating scalable applications that are as functional as they are visually stunning'
                                'Always exploring new technologies to push the boundaries of what is possible in the Developer OS ecosystem.',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 13,
                                  height: 1.5,
                                  letterSpacing: 0.3,
                                  color: isDark ? AppTheme.white.withOpacity(0.85) : AppTheme.black.withOpacity(0.75),
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.verified_user_outlined, size: 22, color: isDark ? AppTheme.white : AppTheme.black),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      'CONNECT WITH ME',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: isDark ? AppTheme.white.withOpacity(0.85) : AppTheme.black.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SocialBtn(
                          icon: FontAwesomeIcons.github,
                          url: 'https://github.com/eng-kerolos-adel',
                          isDark: isDark,
                        ),
                        _SocialBtn(
                          icon: FontAwesomeIcons.linkedinIn,
                          url: 'https://linkedin.com/in/eng-kerolos-adel', 
                          isDark: isDark,
                        ),
                        _SocialBtn(
                          icon: FontAwesomeIcons.globe,
                          url: 'https://kerolos-adel.vercel.app', 
                          isDark: isDark,
                        ),
                        _SocialBtn(
                          icon: FontAwesomeIcons.whatsapp,
                          url: 'https://wa.me/201274363439',
                          isDark: isDark,
                        ),
                        _SocialBtn(
                          icon: FontAwesomeIcons.facebook,
                          url: 'https://www.facebook.com/kerolos.adel.eleshaa',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4, 
              children: [
                _StatCard(
                  label: 'Version',
                  value: 'v1.0.2',
                  icon: Icons.code_rounded,
                  isDark: isDark,
                  delay: 100,
                ),
                _StatCard(
                  label: 'Rating',
                  value: '4.9/5.0',
                  icon: Icons.star_outline_rounded,
                  isDark: isDark,
                  delay: 200,
                  onTap: () {
                    // فتح لينك الستور للتقييم مثلاً
                  },
                ),
                _StatCard(
                  label: 'Status',
                  value: 'Stable',
                  icon: Icons.check_circle_outline_rounded,
                  isDark: isDark,
                  delay: 300,
                ),
                _StatCard(
                  label: 'Feedback',
                  value: 'Send Now',
                  icon: Icons.alternate_email_rounded,
                  isDark: isDark,
                  delay: 400,
                  onTap: () {
                    // فتح الايميل مثلاً
                  },
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark;
  final int delay;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact(); // ده اهتزاز خفيف جداً واحترافي
        onTap;
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppTheme.accent),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.white : AppTheme.black,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 9,
                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _IconBtn({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
          border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
        ),
        child: Icon(icon, size: 18, color: isDark ? AppTheme.white : AppTheme.black),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String url;
  final bool isDark;

  const _SocialBtn({required this.icon, required this.url, required this.isDark});

  Future<void> _launchUrl() async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launchUrl,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05),
        ),
        child: FaIcon(
          icon,
          size: 20,
          color: isDark ? AppTheme.white : AppTheme.black,
        ),
      ),
    );
  }
}