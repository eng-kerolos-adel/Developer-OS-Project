import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../domain/models/project.dart';
import '../../providers/project_provider.dart';

class ProjectTimelineScreen extends ConsumerWidget {
  final String projectId;

  const ProjectTimelineScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(projectsProvider).asData?.value ?? [];
    final project = projects.where((p) => p.id == projectId).firstOrNull;

    if (project == null) {
      return Scaffold(
        body: Center(
          child: Text('Project not found',
              style: TextStyle(color: isDark ? AppTheme.white : AppTheme.black)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(RouteConstants.projectDetail(projectId)),
                    child: Icon(Icons.arrow_back_ios,
                        color: isDark ? AppTheme.white : AppTheme.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '// ${project.name}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Project Roadmap',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 12),

            // Progress summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(
                      label: 'Total Weeks',
                      value: '${project.roadmap.length}',
                      isDark: isDark,
                    ),
                    _SummaryStat(
                      label: 'Completed',
                      value: '${project.roadmap.where((w) => w.completed).length}',
                      isDark: isDark,
                    ),
                    _SummaryStat(
                      label: 'Remaining',
                      value:
                          '${project.roadmap.where((w) => !w.completed).length}',
                      isDark: isDark,
                    ),
                    _SummaryStat(
                      label: 'Progress',
                      value: '${project.completionPercentage}%',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 8),

            // Timeline
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 8, 20, 32),
                physics: const BouncingScrollPhysics(),
                itemCount: project.roadmap.length,
                itemBuilder: (context, index) {
                  final week = project.roadmap[index];
                  final isFirst = index == 0;
                  final isLast = index == project.roadmap.length - 1;
                  final isCurrent = !week.completed &&
                      (index == 0 ||
                          project.roadmap[index - 1].completed);

                  return TimelineTile(
                    alignment: TimelineAlign.manual,
                    lineXY: 0.08,
                    isFirst: isFirst,
                    isLast: isLast,
                    indicatorStyle: IndicatorStyle(
                      width: 28,
                      height: 28,
                      indicator: _TimelineIndicator(
                        completed: week.completed,
                        isCurrent: isCurrent,
                        weekNumber: week.weekNumber,
                        isDark: isDark,
                      ),
                    ),
                    beforeLineStyle: LineStyle(
                      color: week.completed
                          ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.4)
                          : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                      thickness: 1.5,
                    ),
                    afterLineStyle: LineStyle(
                      color: week.completed
                          ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.4)
                          : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                      thickness: 1.5,
                    ),
                    endChild: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                      child: GlassCard(
                        onTap: () {
                          ref.read(projectControllerProvider.notifier)
                              .toggleWeekComplete(project, index);
                        },
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Week ${week.weekNumber}: ${week.title}',
                                    style: TextStyle(
                                      fontFamily: 'Syne',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: week.completed
                                          ? (isDark ? AppTheme.gray : AppTheme.lightGray)
                                          : (isDark ? AppTheme.white : AppTheme.black),
                                      decoration: week.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: (isDark ? AppTheme.white : AppTheme.black)
                                          .withOpacity(0.1),
                                    ),
                                    child: Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppTheme.white : AppTheme.black,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (!week.completed) ...[
                              const SizedBox(height: 6),
                              Text(
                                week.description,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...week.tasks.map((task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.circle,
                                            size: 5,
                                            color: isDark
                                                ? AppTheme.gray
                                                : AppTheme.lightGray,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task,
                                            style: TextStyle(
                                              fontFamily: 'JetBrainsMono',
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppTheme.lightGray
                                                  : AppTheme.gray,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],

                            const SizedBox(height: 8),
                            Text(
                              week.completed
                                  ? '✓ Tap to mark incomplete'
                                  : 'Tap to mark complete',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 9,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 60).ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineIndicator extends StatelessWidget {
  final bool completed;
  final bool isCurrent;
  final int weekNumber;
  final bool isDark;

  const _TimelineIndicator({
    required this.completed,
    required this.isCurrent,
    required this.weekNumber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed
            ? (isDark ? AppTheme.white : AppTheme.black)
            : isCurrent
                ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.15)
                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05),
        border: Border.all(
          color: completed
              ? (isDark ? AppTheme.white : AppTheme.black)
              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Center(
        child: completed
            ? Icon(Icons.check,
                size: 14,
                color: isDark ? AppTheme.black : AppTheme.white)
            : Text(
                '$weekNumber',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),
              ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.white : AppTheme.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            color: isDark ? AppTheme.gray : AppTheme.lightGray,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
