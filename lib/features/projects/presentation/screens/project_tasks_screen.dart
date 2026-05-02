import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../domain/models/project.dart';
import '../../providers/project_provider.dart';
import '../../../ai/services/ai_provider.dart';

class ProjectTasksScreen extends ConsumerStatefulWidget {
  final String projectId;

  // // 2. ضيف السطر ده هنا (لو مش موجود)
  // final Project? project;

  // // 3. عدل الـ Constructor عشان يستلم الـ project
  // // const ProjectTasksScreen({super.key, this.project});

  const ProjectTasksScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends ConsumerState<ProjectTasksScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(tasksProvider(widget.projectId));
    final projects = ref.watch(projectsProvider).asData?.value ?? [];
    final project = projects.where((p) => p.id == widget.projectId).firstOrNull;

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
                    onTap: () => context.go(RouteConstants.projectDetail(widget.projectId)),
                    child: Icon(Icons.arrow_back_ios,
                        color: isDark ? AppTheme.white : AppTheme.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '// ${project?.name ?? 'project'}',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Task Board',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddTaskDialog(context, isDark),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        border: Border.all(
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                        ),
                      ),
                      child: Icon(Icons.add, size: 18,
                          color: isDark ? AppTheme.white : AppTheme.black),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            // Kanban columns
            Expanded(
              child: tasksAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppTheme.white : AppTheme.black,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) {
                  final todoTasks =
                      tasks.where((t) => t.status == AppConstants.taskTodo).toList();
                  final inProgressTasks = tasks
                      .where((t) => t.status == AppConstants.taskInProgress)
                      .toList();
                  final doneTasks =
                      tasks.where((t) => t.status == AppConstants.taskDone).toList();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _KanbanColumn(
                          title: 'TO DO',
                          tasks: todoTasks,
                          status: AppConstants.taskTodo,
                          projectId: widget.projectId,
                          isDark: isDark,
                          accentColor:
                              (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.5),
                        ),
                      ),
                      Expanded(
                        child: _KanbanColumn(
                          title: 'IN PROGRESS',
                          tasks: inProgressTasks,
                          status: AppConstants.taskInProgress,
                          projectId: widget.projectId,
                          isDark: isDark,
                          accentColor: isDark ? AppTheme.silver : AppTheme.gray,
                        ),
                      ),
                      Expanded(
                        child: _KanbanColumn(
                          title: 'DONE',
                          tasks: doneTasks,
                          status: AppConstants.taskDone,
                          projectId: widget.projectId,
                          isDark: isDark,
                          accentColor:
                              (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.3),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';
    String status = AppConstants.taskTodo;
    final projects = ref.watch(projectsProvider).asData?.value ?? [];
    final project = projects.where((p) => p.id == widget.projectId).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Task',
                  style: TextStyle(
                    fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.white : AppTheme.black,
                  )),
              const SizedBox(height: 16),
              GlassTextField(controller: titleCtrl, hintText: 'Task title'),
              const SizedBox(height: 10),
              // حقل الوصف مع زرار الذكاء الاصطناعي
              Row(
                children: [
                  Expanded(
                    child: GlassTextField(
                        controller: descCtrl, hintText: 'Description', maxLines: 2),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (titleCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a title first!')));
                        return;
                      }
                      // إظهار حالة التحميل جوه الحقل مؤقتاً
                      descCtrl.text = "✨ Generating...";
                      final desc = await ref.read(aiGenerationProvider.notifier)
                          .generateTaskDesc(titleCtrl.text, project?.name ?? 'Project');
                      if (desc != null) {
                        descCtrl.text = desc;
                      } else {
                        descCtrl.text = "Error generating text.";
                      }
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.amber),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Priority: ', style: TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 12,
                    color: isDark ? AppTheme.silver : AppTheme.gray)),
                  ...['low', 'medium', 'high'].map((p) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => setSheetState(() => priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: priority == p
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
                        ),
                        child: Text(p.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 10, fontWeight: FontWeight.w700,
                            color: priority == p
                                ? (isDark ? AppTheme.black : AppTheme.white)
                                : (isDark ? AppTheme.silver : AppTheme.gray),
                          )),
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Column: ', style: TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 12,
                    color: isDark ? AppTheme.silver : AppTheme.gray)),
                  ...[
                    (AppConstants.taskTodo, 'To Do'),
                    (AppConstants.taskInProgress, 'In Progress'),
                    (AppConstants.taskDone, 'Done'),
                  ].map(((String, String) item) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => setSheetState(() => status = item.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: status == item.$1
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
                        ),
                        child: Text(item.$2,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w700,
                            color: status == item.$1
                                ? (isDark ? AppTheme.black : AppTheme.white)
                                : (isDark ? AppTheme.silver : AppTheme.gray),
                          )),
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              GlassButton(
                label: 'Add Task',
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  await ref.read(projectControllerProvider.notifier).createTask(
                    projectId: widget.projectId,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    status: status,
                    priority: priority,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final String title;
  final List<ProjectTask> tasks;
  final String status;
  final String projectId;
  final bool isDark;
  final Color accentColor;

  const _KanbanColumn({
    required this.title,
    required this.tasks,
    required this.status,
    required this.projectId,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<ProjectTask>(
      onAccept: (task) {
        if (task.status != status) {
          ref.read(projectControllerProvider.notifier).updateTaskStatus(task, status);
        }
      },
      builder: (context, candidates, rejected) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 10),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: candidates.isNotEmpty
                        ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05)
                        : Colors.transparent,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _TaskCard(
                      task: tasks[i],
                      isDark: isDark,
                      projectId: projectId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final ProjectTask task;
  final bool isDark;
  final String projectId;

  const _TaskCard({
    required this.task,
    required this.isDark,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = task.priority == 'high'
        ? Colors.red.withOpacity(0.7)
        : task.priority == 'medium'
            ? (isDark ? AppTheme.silver : AppTheme.gray)
            : (isDark ? AppTheme.gray : AppTheme.lightGray);

    return Draggable<ProjectTask>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 140,
            child: _buildCard(priorityColor, ref),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCard(priorityColor, ref)),
      child: _buildCard(priorityColor, ref),
    );
  }

  Widget _buildCard(Color priorityColor, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priorityColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref
                    .read(projectControllerProvider.notifier)
                    .deleteTask(task.projectId, task.id),
                child: Icon(Icons.close, size: 12,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: task.status == AppConstants.taskDone
                  ? (isDark ? AppTheme.gray : AppTheme.lightGray)
                  : (isDark ? AppTheme.white : AppTheme.black),
              decoration: task.status == AppConstants.taskDone
                  ? TextDecoration.lineThrough
                  : null,
              height: 1.4,
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 9,
                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            task.priority.toUpperCase(),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: priorityColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
