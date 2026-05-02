import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/journal/providers/journal_provider.dart';
import 'package:developer_os/features/journal/domain/models/journal_entry.dart';
import '../../../ai/services/ai_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entriesAsync = ref.watch(journalEntriesProvider);

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
                  Text('// dev diary',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Daily Journal',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ]),
                GestureDetector(
                  onTap: () => _showAddEntry(context, isDark),
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

          Expanded(
            child: entriesAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(
                      color: isDark ? AppTheme.white : AppTheme.black,
                      strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📔', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text('No journal entries',
                              style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? AppTheme.white : AppTheme.black)),
                          const SizedBox(height: 6),
                          Text('// write about your day',
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.gray
                                      : AppTheme.lightGray)),
                          const SizedBox(height: 24),
                          GlassButton(
                            label: 'Write Entry',
                            width: 180,
                            onPressed: () => _showAddEntry(context, isDark),
                          ),
                        ]).animate().fadeIn(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    return Dismissible(
                      key: Key(entry.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref
                          .read(journalControllerProvider.notifier)
                          .deleteEntry(entry.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    DateFormat('EEE, dd MMM yyyy')
                                        .format(entry.date),
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 11,
                                      color: isDark
                                          ? AppTheme.gray
                                          : AppTheme.lightGray,
                                    )),
                                Row(children: [
                                  Text(entry.moodEmoji,
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  _ProductivityDots(
                                      score: entry.productivityScore,
                                      isDark: isDark),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(entry.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12,
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.lightGray
                                      : AppTheme.gray,
                                )),
                            if (entry.tags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: entry.tags
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            color: (isDark
                                                    ? AppTheme.white
                                                    : AppTheme.black)
                                                .withOpacity(0.07),
                                          ),
                                          child: Text('#$tag',
                                              style: TextStyle(
                                                fontFamily: 'JetBrainsMono',
                                                fontSize: 10,
                                                color: isDark
                                                    ? AppTheme.silver
                                                    : AppTheme.gray,
                                              )),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: (i * 60).ms),
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

  void _showAddEntry(BuildContext context, bool isDark) {
    final contentCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    String mood = 'good';
    int productivity = 3;

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
          child: SingleChildScrollView(
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
                        .withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text("Today's Entry",
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: contentCtrl,
                      hintText: 'What did you build today? What did you learn?',
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (contentCtrl.text.isEmpty) return;
                      final oldText = contentCtrl.text;
                      contentCtrl.text = "✨ Summarizing...";
                      final summary = await ref.read(aiGenerationProvider.notifier)
                          .summarizeJournal(oldText);
                      contentCtrl.text = summary ?? oldText;
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GlassTextField(
                controller: tagsCtrl,
                hintText: 'Tags: Flutter, Firebase, Bug Fix (comma separated)',
              ),
              const SizedBox(height: 12),

              // Mood
              Text('Mood',
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.silver : AppTheme.gray)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final m in [
                    ('great', '🚀'),
                    ('good', '😊'),
                    ('okay', '😐'),
                    ('bad', '😔')
                  ])
                    GestureDetector(
                      onTap: () => setS(() => mood = m.$1),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: mood == m.$1
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black)
                                  .withOpacity(0.07),
                          border: Border.all(
                              color: mood == m.$1
                                  ? (isDark ? AppTheme.white : AppTheme.black)
                                  : Colors.transparent),
                        ),
                        child: Text(m.$2,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Productivity
              Text('Productivity: $productivity/5',
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.silver : AppTheme.gray)),
              Slider(
                value: productivity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: isDark ? AppTheme.white : AppTheme.black,
                inactiveColor: (isDark ? AppTheme.white : AppTheme.black)
                    .withOpacity(0.2),
                onChanged: (v) => setS(() => productivity = v.round()),
              ),
              const SizedBox(height: 8),

              GlassButton(
                label: 'Save Entry',
                onPressed: () async {
                  if (contentCtrl.text.trim().isEmpty) return;
                  final tags = tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  await ref.read(journalControllerProvider.notifier).addEntry(
                        content: contentCtrl.text.trim(),
                        tags: tags,
                        mood: mood,
                        productivityScore: productivity,
                        date: DateTime.now(),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
          )
        );
      }),
    );
  }
}

class _ProductivityDots extends StatelessWidget {
  final int score;
  final bool isDark;
  const _ProductivityDots({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < score;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (isDark ? AppTheme.white : AppTheme.black)
                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
          ),
        );
      }),
    );
  }
}