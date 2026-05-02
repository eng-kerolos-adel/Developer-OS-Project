import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/interview/providers/interview_provider.dart';
import 'package:developer_os/features/interview/domain/models/interview_models.dart';
import '../../../ai/services/ai_provider.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('// career tracker',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Interview Prep',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ]),
                GestureDetector(
                  onTap: () {
                    if (_tabController.index == 0) {
                      _showAddApplication(context, isDark);
                    } else {
                      _showAddProblem(context, isDark);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (isDark ? AppTheme.white : AppTheme.black)
                          .withOpacity(0.07),
                      border: Border.all(
                          color: (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.1)),
                    ),
                    child: Icon(Icons.add,
                        size: 20,
                        color: isDark ? AppTheme.white : AppTheme.black),
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,

                labelColor: isDark ? AppTheme.black : AppTheme.white,
                unselectedLabelColor: isDark ? AppTheme.gray : AppTheme.lightGray,

                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),

                labelStyle: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
                tabs: const [
                  Tab(text: 'APPLICATIONS'),
                  Tab(text: 'DSA PROBLEMS'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ApplicationsTab(isDark: isDark),
                _DSATab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddApplication(BuildContext context, bool isDark) {
    final companyCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassContainer(
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
            Text('Add Application',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.white : AppTheme.black)),
            const SizedBox(height: 16),
            GlassTextField(
                controller: companyCtrl, hintText: 'Company name'),
            const SizedBox(height: 10),
            GlassTextField(
                controller: positionCtrl, hintText: 'Position / Role'),
            const SizedBox(height: 10),
            GlassTextField(
                controller: urlCtrl,
                hintText: 'Job URL (optional)',
                keyboardType: TextInputType.url),
            const SizedBox(height: 10),
            GlassTextField(
                controller: notesCtrl,
                hintText: 'Notes (optional)',
                maxLines: 2),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Add Application',
              onPressed: () async {
                if (companyCtrl.text.isEmpty || positionCtrl.text.isEmpty)
                  return;
                await ref
                    .read(interviewControllerProvider.notifier)
                    .addApplication(
                      company: companyCtrl.text.trim(),
                      position: positionCtrl.text.trim(),
                      jobUrl: urlCtrl.text.trim().isEmpty
                          ? null
                          : urlCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProblem(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String difficulty = 'medium';
    String category = 'Array';

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
              Text('Add DSA Problem',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 16),
              GlassTextField(
                  controller: titleCtrl, hintText: 'Problem title'),
              const SizedBox(height: 10),
              GlassTextField(
                  controller: urlCtrl,
                  hintText: 'LeetCode URL (optional)',
                  keyboardType: TextInputType.url),
              const SizedBox(height: 12),
              // Difficulty
              Row(children: [
                Text('Difficulty: ',
                    style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: isDark ? AppTheme.silver : AppTheme.gray)),
                ...['easy', 'medium', 'hard'].map((d) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () => setS(() => difficulty = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: difficulty == d
                                ? _difficultyColor(d)
                                : _difficultyColor(d).withOpacity(0.1),
                          ),
                          child: Text(d.toUpperCase(),
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: difficulty == d
                                      ? AppTheme.white
                                      : _difficultyColor(d))),
                        ),
                      ),
                    )),
              ]),
              const SizedBox(height: 12),
              // Category
              GlassCard(
                padding: EdgeInsets.zero,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    dropdownColor:
                        isDark ? AppTheme.darkMid : AppTheme.white,
                    style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                        color: isDark ? AppTheme.white : AppTheme.black),
                    items: DSAProblem.categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setS(() => category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassButton(
                label: 'Add Problem',
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  await ref
                      .read(interviewControllerProvider.notifier)
                      .addDSAProblem(
                        title: titleCtrl.text.trim(),
                        difficulty: difficulty,
                        category: category,
                        leetcodeUrl: urlCtrl.text.trim().isEmpty
                            ? null
                            : urlCtrl.text.trim(),
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

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// =====================
// Applications Tab
// =====================
class _ApplicationsTab extends ConsumerWidget {
  final bool isDark;
  const _ApplicationsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(applicationsProvider);

    return appsAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(
              color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (apps) {
        if (apps.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📨',
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No applications yet',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                  const SizedBox(height: 6),
                  Text('// track your job applications',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ]).animate().fadeIn(),
          );
        }

        // Stats row
        final statuses = {
          'applied': apps.where((a) => a.status == 'applied').length,
          'interview': apps.where((a) => a.status == 'interview').length,
          'offer': apps.where((a) => a.status == 'offer').length,
          'rejected': apps.where((a) => a.status == 'rejected').length,
        };

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _AppStatChip(label: '${statuses['applied']} Applied', isDark: isDark),
                const SizedBox(width: 8),
                _AppStatChip(label: '${statuses['interview']} Interview', isDark: isDark),
                const SizedBox(width: 8),
                _AppStatChip(label: '${statuses['offer']} Offer 🎉', isDark: isDark),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: apps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final app = apps[i];
                  return Dismissible(
                    key: Key(app.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref
                        .read(interviewControllerProvider.notifier)
                        .deleteApplication(app.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                                InterviewApplication.statusEmoji(app.status),
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(app.company,
                                        style: TextStyle(
                                            fontFamily: 'Syne',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppTheme.white
                                                : AppTheme.black)),
                                    Text(app.position,
                                        style: TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 12,
                                            color: isDark
                                                ? AppTheme.gray
                                                : AppTheme.lightGray)),
                                  ]),
                            ),
                            // Status dropdown
                            DropdownButton<String>(
                              value: app.status,
                              underline: const SizedBox.shrink(),
                              dropdownColor:
                                  isDark ? AppTheme.darkMid : AppTheme.white,
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  color: isDark ? AppTheme.white : AppTheme.black),
                              items: InterviewApplication.statuses
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.toUpperCase())))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(interviewControllerProvider.notifier)
                                      .updateStatus(app, val);
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12,
                                color: isDark
                                    ? AppTheme.gray
                                    : AppTheme.lightGray),
                            const SizedBox(width: 4),
                            Text(
                                DateFormat('dd MMM yyyy')
                                    .format(app.appliedDate),
                                style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 11,
                                    color: isDark
                                        ? AppTheme.gray
                                        : AppTheme.lightGray)),
                            
                            const Spacer(), // دي بتزق الأيقونات لليمين

                            // لو في لينك للوظيفة اعرضه الأول
                            if (app.jobUrl != null) ...[
                              GestureDetector(
                                onTap: () => launchUrl(
                                    Uri.parse(app.jobUrl!),
                                    mode: LaunchMode.externalApplication),
                                child: Icon(Icons.open_in_new,
                                    size: 14,
                                    color: isDark
                                        ? AppTheme.gray
                                        : AppTheme.lightGray),
                              ),
                              const SizedBox(width: 16),
                            ],

                            // 👇 زرار الذكاء الاصطناعي المتصلّح 👇
                            GestureDetector(
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => const Center(
                                    child: CircularProgressIndicator(color: Colors.amber),
                                  ),
                                );

                                try {
                                  final questions = await ref.read(aiGenerationProvider.notifier)
                                      .generateInterviewQuestions(position: app.position, company: app.company);

                                  // أهم سطر عشان التطبيق ميكراشش (لأننا جوه StatelessWidget هنا بنستخدم context.mounted)
                                  if (!context.mounted) return;
                                  Navigator.of(context, rootNavigator: true).pop();

                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true, // عشان لو الأسئلة كتير
                                    builder: (ctx) => GlassContainer(
                                      padding: const EdgeInsets.all(24),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Container(
                                                  width: 40, height: 4,
                                                  decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(2),
                                                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)))),
                                            const SizedBox(height: 20),
                                            Text('✨ Expected Questions', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.white : AppTheme.black)),
                                            const SizedBox(height: 16),
                                            
                                            if (questions.isEmpty) 
                                              Text('Could not generate questions.', style: TextStyle(color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                                            
                                            ...questions.map((q) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12.0),
                                              child: Text('• $q', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, height: 1.5, color: isDark ? AppTheme.lightGray : AppTheme.gray)),
                                            )),
                                            const SizedBox(height: 20), // مسافة تحت عشان الـ Scrolling
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                  }
                                }
                              },
                              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                            ),
                          ]),
                          if (app.notes != null) ...[
                            const SizedBox(height: 6),
                            Text(app.notes!,
                                style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 11,
                                    color: isDark
                                        ? AppTheme.gray
                                        : AppTheme.lightGray)),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 60).ms),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// =====================
// DSA Tab
// =====================
class _DSATab extends ConsumerWidget {
  final bool isDark;
  const _DSATab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problemsAsync = ref.watch(dsaProblemsProvider);

    return problemsAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(
              color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (problems) {
        if (problems.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🧩',
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('No problems yet',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                  const SizedBox(height: 6),
                  Text('// track your DSA practice',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ]).animate().fadeIn(),
          );
        }

        final solved = problems.where((p) => p.isSolved).length;
        final total = problems.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DSAStat(label: 'Total', value: '$total', isDark: isDark),
                    _DSAStat(
                        label: 'Solved',
                        value: '$solved',
                        isDark: isDark,
                        color: Colors.green),
                    _DSAStat(
                        label: 'Remaining',
                        value: '${total - solved}',
                        isDark: isDark,
                        color: Colors.orange),
                    _DSAStat(
                        label: 'Rate',
                        value: total > 0
                            ? '${((solved / total) * 100).round()}%'
                            : '0%',
                        isDark: isDark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: problems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = problems[i];
                  Color diffColor = p.difficulty == 'easy'
                      ? Colors.green
                      : p.difficulty == 'medium'
                          ? Colors.orange
                          : Colors.red;

                  return Dismissible(
                    key: Key(p.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref
                        .read(interviewControllerProvider.notifier)
                        .deleteProblem(p.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    child: GlassCard(
                      onTap: () => ref
                          .read(interviewControllerProvider.notifier)
                          .toggleProblemSolved(p),
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        // Checkbox
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.isSolved
                                ? Colors.green
                                : Colors.transparent,
                            border: Border.all(
                                color: p.isSolved
                                    ? Colors.green
                                    : (isDark
                                        ? AppTheme.gray
                                        : AppTheme.lightGray)),
                          ),
                          child: p.isSolved
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title,
                                    style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: p.isSolved
                                            ? (isDark
                                                ? AppTheme.gray
                                                : AppTheme.lightGray)
                                            : (isDark
                                                ? AppTheme.white
                                                : AppTheme.black),
                                        decoration: p.isSolved
                                            ? TextDecoration.lineThrough
                                            : null)),
                                Text(p.category,
                                    style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 10,
                                        color: isDark
                                            ? AppTheme.gray
                                            : AppTheme.lightGray)),
                              ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: diffColor.withOpacity(0.15),
                          ),
                          child: Text(p.difficulty.toUpperCase(),
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: diffColor)),
                        ),
                        if (p.leetcodeUrl != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => launchUrl(
                                Uri.parse(p.leetcodeUrl!),
                                mode: LaunchMode.externalApplication),
                            child: Icon(Icons.open_in_new,
                                size: 14,
                                color:
                                    isDark ? AppTheme.gray : AppTheme.lightGray),
                          ),
                        ],
                      ]),
                    ),
                  ).animate().fadeIn(delay: (i * 40).ms);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppStatChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _AppStatChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
        border: Border.all(
            color:
                (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              color: isDark ? AppTheme.silver : AppTheme.gray)),
    );
  }
}

class _DSAStat extends StatelessWidget {
  final String label, value;
  final bool isDark;
  final Color? color;
  const _DSAStat(
      {required this.label,
      required this.value,
      required this.isDark,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color ?? (isDark ? AppTheme.white : AppTheme.black))),
      Text(label,
          style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
    ]);
  }
}