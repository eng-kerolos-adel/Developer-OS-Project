import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:developer_os/core/constants/route_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '// project archive',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                    ),
                    Text(
                      'Projects',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.go(RouteConstants.createProject),
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
                    child: Icon(Icons.add, size: 20,
                        color: isDark ? AppTheme.white : AppTheme.black),
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: projectsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppTheme.white : AppTheme.black,
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 56,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                        const SizedBox(height: 16),
                        Text(
                          'No projects yet',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '// init your first project',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassButton(
                          label: 'Create Project',
                          width: 200,
                          onPressed: () => context.go(RouteConstants.createProject),
                        ),
                      ],
                    ).animate().fadeIn(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final project = projects[i];
                    return _ProjectCard(
                      project: project,
                      isDark: isDark,
                      index: i,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;
  final bool isDark;
  final int index;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final githubToken = ref.watch(githubTokenProvider);

    return Dismissible(
      key: Key(project.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) async {
        bool deleteFromGitHub = false;
        return await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (ctx, setS) {
              return AlertDialog(
                backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
                title: Text(
                  'Delete Project',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    color: isDark ? AppTheme.white : AppTheme.black,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete "${project.name}"?',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: isDark ? AppTheme.silver : AppTheme.gray,
                      ),
                    ),
                    if (project.githubUrl != null && githubToken != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: deleteFromGitHub,
                            activeColor: Colors.red,
                            onChanged: (v) => setS(() => deleteFromGitHub = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'Also delete GitHub repo',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (deleteFromGitHub)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: Text(
                            '⚠️ This cannot be undone!',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (deleteFromGitHub && project.githubUrl != null) {
                        await ref
                            .read(deleteGitHubRepoProvider.notifier)
                            .deleteRepo(project.githubUrl!);
                      }
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ),
        );
      },
      onDismissed: (_) => ref.read(projectControllerProvider.notifier).deleteProject(project.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: GlassCard(
        onTap: () => context.go(RouteConstants.projectDetail(project.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.white : AppTheme.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // 🔥 أيقونة التعديل الجديدة
                GestureDetector(
                  onTap: () {
                    // هنا هنوجه المستخدم لصفحة التعديل وهنبعت معاه الـ ID بتاع المشروع
                    // تأكد إنك ضايف الراوت ده في الـ RouteConstants عندك
                    context.go('${RouteConstants.createProject}?editId=${project.id}');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(status: project.status, isDark: isDark),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              project.projectType,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                height: 1.5,
                color: isDark ? AppTheme.lightGray : AppTheme.gray,
              ),
            ),
            const SizedBox(height: 12),
            // Tech stack
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.techStack
                  .take(5)
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
                          border: Border.all(
                            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: isDark ? AppTheme.silver : AppTheme.gray,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (project.startDate != null)
                  Text(
                    DateFormat('MMM yyyy').format(project.startDate!),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                  ),
                const Spacer(),
                if (project.roadmap.isNotEmpty) ...[
                  SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: project.completionPercentage / 100,
                        backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppTheme.white : AppTheme.black,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${project.completionPercentage}%',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.silver : AppTheme.gray,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray,
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusPill({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
        border: Border.all(
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
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