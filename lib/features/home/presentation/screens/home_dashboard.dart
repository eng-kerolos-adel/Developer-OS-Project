import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:developer_os/core/constants/route_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/core/providers/theme_provider.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/github/presentation/widgets/github_stats_widget.dart';

class HomeDashboardContent extends ConsumerWidget {
  const HomeDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).asData?.value;
    final projects = ref.watch(projectsProvider).asData?.value ?? [];
    final user = ref.watch(currentUserProvider);

    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final name = profile?.name ?? user?.displayName ?? 'Developer';

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
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
                        '// ${DateFormat('EEE, dd MMM').format(now)}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$greeting,',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                      Text(
                        name.split(' ').first,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
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
              ),
            ).animate().fadeIn(delay: 100.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                height: 120,
                child: Row(
                  children: [
                    // المربع الأول
                    Expanded(
                      child: _StatCard(
                        label: 'Projects',
                        value: '${projects.length}',
                        icon: Icons.folder_outlined,
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // المربع الثاني
                    Expanded(
                      child: _StatCard(
                        label: 'Active',
                        value: '${projects.where((p) => p.status == 'active').length}',
                        icon: Icons.play_circle_outline,
                        isDark: isDark,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // المربع الثالث
                    Expanded(
                      child: _StatCard(
                        label: 'Done',
                        value: '${projects.where((p) => p.status == 'completed').length}',
                        icon: Icons.check_circle_outline,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // GitHub Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const GitHubStatsWidget(),
            ).animate().fadeIn(delay: 450.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Quick Actions', isDark: isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          label: 'New Project',
                          icon: Icons.add_circle_outline,
                          tag: '// init',
                          onTap: () => context.go(RouteConstants.createProject),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          label: 'Edit Profile',
                          icon: Icons.edit_outlined,
                          tag: '// update',
                          onTap: () => context.go(RouteConstants.editProfile),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          label: 'Add Skill',
                          icon: Icons.psychology_outlined,
                          tag: '// push',
                          onTap: () => context.go(RouteConstants.skills),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          label: 'My Links',
                          icon: Icons.link,
                          tag: '// export',
                          onTap: () => context.go(RouteConstants.links),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Recent Projects
          if (projects.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Recent Projects',
                  isDark: isDark,
                  trailing: TextButton(
                    onPressed: () => context.go(RouteConstants.projects),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: isDark ? AppTheme.silver : AppTheme.gray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final project = projects[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: GlassCard(
                      onTap: () => context.go(RouteConstants.projectDetail(project.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: TextStyle(
                                    fontFamily: 'Syne',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.white : AppTheme.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _StatusBadge(status: project.status, isDark: isDark),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 12,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tech chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: project.techStack
                                .take(4)
                                .map((t) => _TechChip(label: t, isDark: isDark))
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                          // Progress
                          if (project.roadmap.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 10,
                                    color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '${project.completionPercentage}%',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.white : AppTheme.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: project.completionPercentage / 100,
                                backgroundColor:
                                    (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? AppTheme.white : AppTheme.black,
                                ),
                                minHeight: 3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: (600 + i * 100).ms).slideY(begin: 0.1, end: 0),
                  );
                },
                childCount: projects.take(3).length,
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 40,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No projects yet',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '// start building something great',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassButton(
                        label: 'Create Project',
                        onPressed: () => context.go(RouteConstants.createProject),
                        width: 200,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
          border: Border.all(
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
          ),
        ),
        child: Icon(icon, size: 18, color: isDark ? AppTheme.white : AppTheme.black),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: isDark ? AppTheme.silver : AppTheme.gray),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.white : AppTheme.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final String tag;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.tag,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: isDark ? AppTheme.white : AppTheme.black),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tag,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              color: isDark ? AppTheme.gray : AppTheme.lightGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? trailing;

  const _SectionHeader({required this.title, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
        border: Border.all(
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.12),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.silver : AppTheme.gray,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _TechChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
        border: Border.all(
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          color: isDark ? AppTheme.silver : AppTheme.gray,
        ),
      ),
    );
  }
}