import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'package:developer_os/core/constants/route_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';
import 'package:developer_os/features/github/presentation/screens/repo_files_screen.dart';
import '../../../notifications/providers/notification_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      body: projectsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: isDark ? AppTheme.white : AppTheme.black,
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (projects) {
          final project = projects.where((p) => p.id == projectId).firstOrNull;

          if (project == null) {
            return Center(
              child: Text(
                'Project not found',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),
              ),
            );
          }

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(RouteConstants.projects),
                          child: Icon(Icons.arrow_back_ios,
                              color: isDark ? AppTheme.white : AppTheme.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            project.name,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusDropdown(project: project, isDark: isDark),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Info card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.description,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                              height: 1.6,
                              color: isDark ? AppTheme.lightGray : AppTheme.gray,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.category_outlined,
                                label: project.projectType,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _InfoChip(
                                icon: Icons.devices_outlined,
                                label: project.targetPlatform,
                                isDark: isDark,
                              ),
                            ],
                          ),
                          if (project.startDate != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.calendar_today_outlined,
                                  label: DateFormat('dd MMM yyyy').format(project.startDate!),
                                  isDark: isDark,
                                ),
                                if (project.endDate != null) ...[
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    icon: Icons.flag_outlined,
                                    label: DateFormat('dd MMM yyyy').format(project.endDate!),
                                    isDark: isDark,
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (project.githubUrl != null || project.demoUrl != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (project.githubUrl != null)
                                  _LinkButton(
                                    label: 'GitHub',
                                    url: project.githubUrl!,
                                    isDark: isDark,
                                  ),
                                if (project.githubUrl != null && project.demoUrl != null)
                                  const SizedBox(width: 8),
                                if (project.demoUrl != null)
                                  _LinkButton(
                                    label: 'Live Demo',
                                    url: project.demoUrl!,
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                            // Browse Files button
                            if (project.githubUrl != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  final uri = Uri.parse(project.githubUrl!);
                                  final segments = uri.pathSegments;
                                  if (segments.length >= 2) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RepoFilesScreen(
                                          repoName: segments[1],
                                          projectName: project.name,
                                          githubUrl: project.githubUrl,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                                    border: Border.all(
                                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.12)),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.folder_open_outlined, size: 14,
                                        color: isDark ? AppTheme.silver : AppTheme.gray),
                                    const SizedBox(width: 6),
                                    Text('Browse Files',
                                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                                            color: isDark ? AppTheme.silver : AppTheme.gray)),
                                  ]),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ),

                // Tech stack
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tech Stack',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: project.techStack
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                                        border: Border.all(
                                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        t,
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 11,
                                          color: isDark ? AppTheme.silver : AppTheme.gray,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),

                // Progress
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Overall Progress',
                                style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.white : AppTheme.black,
                                ),
                              ),
                              Text(
                                '${project.completionPercentage}%',
                                style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.white : AppTheme.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: project.completionPercentage / 100,
                              backgroundColor:
                                  (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppTheme.white : AppTheme.black,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${project.roadmap.where((w) => w.completed).length} of ${project.roadmap.length} weeks completed',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),

                // Action buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.timeline,
                            label: 'Roadmap',
                            sublabel: '${project.roadmap.length} weeks',
                            onTap: () => context.go(RouteConstants.projectTimeline(project.id)),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.view_kanban_outlined,
                            label: 'Tasks',
                            sublabel: 'Kanban board',
                            onTap: () => context.go(RouteConstants.projectTasks(project.id)),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusDropdown extends ConsumerWidget {
  final Project project;
  final bool isDark;

  const _StatusDropdown({required this.project, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const statuses = ['planning', 'active', 'on_hold', 'completed', 'archived'];
    return DropdownButton<String>(
      value: project.status,
      underline: const SizedBox.shrink(),
      dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
      style: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 11,
        color: isDark ? AppTheme.white : AppTheme.black,
      ),
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          ref.read(projectControllerProvider.notifier).updateProject(
                project.copyWith(status: val),
          );
        }
        if (val == 'completed') {
          // ✅ Notify
          ref.read(notifControllerProvider).projectCompleted(project.name);
        }
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: isDark ? AppTheme.gray : AppTheme.lightGray),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: isDark ? AppTheme.gray : AppTheme.lightGray,
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final bool isDark;

  const _LinkButton({required this.label, required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
          border: Border.all(
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new, size: 12,
                color: isDark ? AppTheme.silver : AppTheme.gray),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                color: isDark ? AppTheme.silver : AppTheme.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: isDark ? AppTheme.white : AppTheme.black),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.white : AppTheme.black,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: isDark ? AppTheme.gray : AppTheme.lightGray,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.arrow_forward, size: 14,
                color: isDark ? AppTheme.gray : AppTheme.lightGray),
          ),
        ],
      ),
    );
  }
}