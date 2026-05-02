// lib/features/achievements/presentation/screens/achievements_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';
// import 'package:developer_os/features/analytics/providers/analytics_provider.dart';
// import 'package:developer_os/features/pomodoro/presentation/screens/pomodoro_screen.dart';
import 'package:developer_os/features/notifications/providers/notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String category;
  final int requiredValue;
  final String metric;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.requiredValue,
    required this.metric,
    required this.xpReward,
  });
}

class UnlockedAchievement {
  final String achievementId;
  final DateTime unlockedAt;

  const UnlockedAchievement({required this.achievementId, required this.unlockedAt});

  Map<String, dynamic> toMap() => {
    'achievementId': achievementId,
    'unlockedAt': unlockedAt.millisecondsSinceEpoch,
  };

  factory UnlockedAchievement.fromMap(Map<String, dynamic> m) => UnlockedAchievement(
    achievementId: m['achievementId'] ?? '',
    unlockedAt: DateTime.fromMillisecondsSinceEpoch(m['unlockedAt'] ?? 0),
  );
}

// ═══════════════════════════════════════════════════════════════════
// Achievements Data
// ═══════════════════════════════════════════════════════════════════
class AchievementsData {
  static const List<Achievement> all = [
    // Projects
    Achievement(id: 'first_project', title: 'First Steps', description: 'Create your first project',
        emoji: '🚀', category: 'projects', requiredValue: 1, metric: 'projects', xpReward: 50),
    Achievement(id: 'five_projects', title: 'Builder', description: 'Create 5 projects',
        emoji: '🏗️', category: 'projects', requiredValue: 5, metric: 'projects', xpReward: 100),
    Achievement(id: 'ten_projects', title: 'Prolific Dev', description: 'Create 10 projects',
        emoji: '⚡', category: 'projects', requiredValue: 10, metric: 'projects', xpReward: 200),
    Achievement(id: 'twenty_projects', title: 'Project Master', description: 'Create 20 projects',
        emoji: '👑', category: 'projects', requiredValue: 20, metric: 'projects', xpReward: 500),
    Achievement(id: 'first_complete', title: 'Ship It!', description: 'Complete your first project',
        emoji: '✅', category: 'projects', requiredValue: 1, metric: 'completed_projects', xpReward: 150),
    Achievement(id: 'five_complete', title: 'Finisher', description: 'Complete 5 projects',
        emoji: '🎯', category: 'projects', requiredValue: 5, metric: 'completed_projects', xpReward: 300),
    // Skills
    Achievement(id: 'first_skill', title: 'Student', description: 'Add your first skill',
        emoji: '📝', category: 'skills', requiredValue: 1, metric: 'skills', xpReward: 25),
    Achievement(id: 'ten_skills', title: 'Multi-Talented', description: 'Add 10 skills',
        emoji: '🎓', category: 'skills', requiredValue: 10, metric: 'skills', xpReward: 100),
    Achievement(id: 'twenty_skills', title: 'Full Stack', description: 'Add 20 skills',
        emoji: '🌟', category: 'skills', requiredValue: 20, metric: 'skills', xpReward: 250),
    Achievement(id: 'first_cert', title: 'Certified', description: 'Add your first certificate',
        emoji: '🏆', category: 'skills', requiredValue: 1, metric: 'certs', xpReward: 75),
    Achievement(id: 'five_certs', title: 'Credential Hunter', description: 'Add 5 certificates',
        emoji: '🎖️', category: 'skills', requiredValue: 5, metric: 'certs', xpReward: 200),
    // DSA
    Achievement(id: 'first_dsa', title: 'Algorithmist', description: 'Solve your first DSA problem',
        emoji: '🧩', category: 'interview', requiredValue: 1, metric: 'dsa_solved', xpReward: 25),
    Achievement(id: 'ten_dsa', title: 'Problem Solver', description: 'Solve 10 DSA problems',
        emoji: '🎯', category: 'interview', requiredValue: 10, metric: 'dsa_solved', xpReward: 150),
    Achievement(id: 'fifty_dsa', title: 'LeetCode Grinder', description: 'Solve 50 DSA problems',
        emoji: '💡', category: 'interview', requiredValue: 50, metric: 'dsa_solved', xpReward: 500),
    Achievement(id: 'hundred_dsa', title: 'Algorithm Master', description: 'Solve 100 DSA problems',
        emoji: '🧠', category: 'interview', requiredValue: 100, metric: 'dsa_solved', xpReward: 1000),
    // Journal
    Achievement(id: 'first_journal', title: 'Reflection', description: 'Write your first journal entry',
        emoji: '📔', category: 'journal', requiredValue: 1, metric: 'journal_entries', xpReward: 20),
    Achievement(id: 'thirty_journal', title: 'Daily Dev', description: 'Write 30 journal entries',
        emoji: '✍️', category: 'journal', requiredValue: 30, metric: 'journal_entries', xpReward: 200),
    // Snippets
    Achievement(id: 'first_snippet', title: 'Code Saver', description: 'Save your first code snippet',
        emoji: '💾', category: 'snippets', requiredValue: 1, metric: 'snippets', xpReward: 20),
    Achievement(id: 'twenty_snippets', title: 'Snippet Master', description: 'Save 20 code snippets',
        emoji: '📚', category: 'snippets', requiredValue: 20, metric: 'snippets', xpReward: 150),
  ];

  static Map<String, Achievement> get byId => {for (final a in all) a.id: a};
  static List<Achievement> byCategory(String c) => all.where((a) => a.category == c).toList();
}

// ═══════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════
final unlockedAchievementsProvider = StreamProvider<List<UnlockedAchievement>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('achievements')
      .snapshots()
      .map((s) => s.docs.map((d) => UnlockedAchievement.fromMap(d.data())).toList());
});

final totalXPProvider = Provider<int>((ref) {
  final unlocked = ref.watch(unlockedAchievementsProvider).asData?.value ?? [];
  final byId = AchievementsData.byId;
  return unlocked.fold(0, (sum, u) => sum + (byId[u.achievementId]?.xpReward ?? 0));
});

final developerLevelProvider = Provider<Map<String, dynamic>>((ref) {
  final xp = ref.watch(totalXPProvider);
  const levels = [
    {'level': 1, 'title': 'Rookie',        'emoji': '🐣',  'minXP': 0,     'maxXP': 200},
    {'level': 2, 'title': 'Junior Dev',    'emoji': '💻',  'minXP': 200,   'maxXP': 500},
    {'level': 3, 'title': 'Developer',     'emoji': '⚡',  'minXP': 500,   'maxXP': 1000},
    {'level': 4, 'title': 'Senior Dev',    'emoji': '🔥',  'minXP': 1000,  'maxXP': 2000},
    {'level': 5, 'title': 'Lead Dev',      'emoji': '🚀',  'minXP': 2000,  'maxXP': 4000},
    {'level': 6, 'title': 'Architect',     'emoji': '🏗️', 'minXP': 4000,  'maxXP': 7000},
    {'level': 7, 'title': 'Principal',     'emoji': '⭐',  'minXP': 7000,  'maxXP': 12000},
    {'level': 8, 'title': 'Distinguished', 'emoji': '👑',  'minXP': 12000, 'maxXP': 20000},
    {'level': 9, 'title': 'Fellow',        'emoji': '🌟',  'minXP': 20000, 'maxXP': 99999},
  ];

  // 1. هنا بنجيب المستوى الحالي بس بنقارنه بالـ Index بتاعه من الأول
int currentIdx = 0;
for (int i = 0; i < levels.length; i++) {
  if (xp >= (levels[i]['minXP'] as int)) {
    currentIdx = i;
  }
}

// 2. وبكده الـ current هيبقى هو المستوى اللي واقف عليه الـ Index
final current = levels[currentIdx];
  final next = currentIdx < levels.length - 1 ? levels[currentIdx + 1] : current;
  final minXP = current['minXP'] as int;
  final maxXP = next['minXP'] as int;
  final progress = maxXP > minXP ? (xp - minXP) / (maxXP - minXP) : 1.0;

  return {
    ...current,
    'xp': xp,
    'nextXP': maxXP,
    'progress': progress.clamp(0.0, 1.0),
  };
});

// ── Achievement Checker ──────────────────────────────────────────────
final achievementCheckerProvider = Provider<AchievementChecker>((ref) {
  return AchievementChecker(ref);
});

// ═══════════════════════════════════════════════════════════════════
// ✅ FIXED Background Observer
// المشاكل اللي كانت موجودة:
// 1. كان بيتكالل checkAndUnlock() على كل تغيير صغير → إشعارات متكررة
// 2. الـ analytics كانت بتديه قيم وهمية في الأول → achievements بتتفتح بالغلط
//
// الحل:
// - استخدام Debounce: ننتظر 3 ثواني بعد آخر تغيير قبل ما نعمل check
// - التحقق إن الداتا loaded فعلاً قبل الـ check
// ═══════════════════════════════════════════════════════════════════
final backgroundAchievementObserver = Provider<void>((ref) {
  // بنستخدم Timer كـ debounce
  Timer? debounce;

  void scheduleCheck() {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 3), () {
      ref.read(achievementCheckerProvider).checkAndUnlock();
    });
  }

  // مراقبة التغييرات
  ref.listen(projectsProvider, (prev, next) {
    if (next.hasValue && next.value != prev?.value) scheduleCheck();
  });

  ref.listen(skillsProvider, (prev, next) {
    if (next.hasValue && next.value != prev?.value) scheduleCheck();
  });

  ref.listen(certificatesProvider, (prev, next) {
    if (next.hasValue && next.value != prev?.value) scheduleCheck();
  });

  ref.onDispose(() => debounce?.cancel());
});

// ═══════════════════════════════════════════════════════════════════
// Achievement Checker — الـ Logic الحقيقي
// ═══════════════════════════════════════════════════════════════════
class AchievementChecker {
  final Ref _ref;

  // ✅ FIX: بنحفظ الـ achievements اللي بعتنا عليها إشعار في هذه الجلسة
  // عشان منبعتش إشعار مرتين لنفس الـ achievement في نفس الجلسة
  final Set<String> _notifiedThisSession = {};

  AchievementChecker(this._ref);

  Future<List<Achievement>> checkAndUnlock() async {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return [];

    // ✅ FIX: لازم الداتا كلها loaded قبل ما نشيك — لو أي حاجة لسه بتحمل، ننتظر
    final projectsAsync   = _ref.read(projectsProvider);
    final skillsAsync     = _ref.read(skillsProvider);
    final certsAsync      = _ref.read(certificatesProvider);

    if (projectsAsync.isLoading ||
        skillsAsync.isLoading ||
        certsAsync.isLoading) {
      return [];
    }

    // ✅ FIX: بنقرأ الـ unlocked من Firestore مباشرة (مش من الـ provider)
    // عشان يكون أكثر دقة ونتجنب الـ race conditions
    Set<String> unlockedIds;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('achievements')
          .get();
      unlockedIds = snap.docs.map((d) => d.id).toSet();
    } catch (_) {
      return [];
    }

    final projects   = projectsAsync.asData?.value ?? [];
    final skills     = skillsAsync.asData?.value ?? [];
    final certs      = certsAsync.asData?.value ?? [];

    // ✅ FIX: بنحسب journal_entries, snippets, dsa_solved من Firestore مباشرة
    // عشان الـ metrics دي مش موجودة في الـ providers اللي عندنا
    int journalEntries = 0;
    int snippetsCount  = 0;
    int dsaSolved      = 0;
    try {
      final journal  = await FirebaseFirestore.instance.collection('users').doc(uid).collection('journal').count().get();
      final snippets = await FirebaseFirestore.instance.collection('users').doc(uid).collection('snippets').count().get();
      final dsa      = await FirebaseFirestore.instance.collection('users').doc(uid).collection('dsa_problems')
          .where('solved', isEqualTo: true).count().get();
      journalEntries = journal.count ?? 0;
      snippetsCount  = snippets.count ?? 0;
      dsaSolved      = dsa.count ?? 0;
    } catch (_) {}

    final metrics = {
      'projects':           projects.length,
      'completed_projects': projects.where((p) => p.status == 'completed').length,
      'skills':             skills.length,
      'certs':              certs.length,
      'journal_entries':    journalEntries,
      'snippets':           snippetsCount,
      'dsa_solved':         dsaSolved,
    };

    final newlyUnlocked = <Achievement>[];
    int prevXP = 0;
    int newXP  = 0;

    // حساب الـ XP الحالية قبل الـ check
    final allById = AchievementsData.byId;
    for (final id in unlockedIds) {
      prevXP += allById[id]?.xpReward ?? 0;
    }

    // ✅ FIX: الـ batch write لتوفير الـ Firestore calls
    final batch = FirebaseFirestore.instance.batch();
    bool hasBatchChanges = false;

    for (final achievement in AchievementsData.all) {
      final value = metrics[achievement.metric] ?? 0;
      final isUnlocked = unlockedIds.contains(achievement.id);

      if (!isUnlocked && value >= achievement.requiredValue) {
        // 🔓 Unlock it
        final ref = FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('achievements').doc(achievement.id);

        batch.set(ref, UnlockedAchievement(
          achievementId: achievement.id,
          unlockedAt: DateTime.now(),
        ).toMap());

        newlyUnlocked.add(achievement);
        newXP += achievement.xpReward;
        hasBatchChanges = true;

        // ✅ FIX: بنبعت الإشعار بس لو ما بعتناهوش في هذه الجلسة
        if (!_notifiedThisSession.contains(achievement.id)) {
          _notifiedThisSession.add(achievement.id);
          await _ref.read(notifControllerProvider).achievementUnlocked(
            achievement.title,
            achievement.xpReward,
          );
        }
      }
      // NOTE: بنزيل الـ achievementLocked logic اللي كانت بتسبب مشاكل
      // الإنجاز مرة بيتفتح مش بيتقفل تاني
    }

    if (hasBatchChanges) {
      await batch.commit();
    }

    // ✅ Check for level up
    if (newXP > 0) {
      final totalPrevXP = prevXP;
      final totalNewXP  = prevXP + newXP;
      _checkLevelUp(totalPrevXP, totalNewXP);
    }

    return newlyUnlocked;
  }

  void _checkLevelUp(int prevXP, int newXP) {
    const levels = [0, 200, 500, 1000, 2000, 4000, 7000, 12000, 20000];
    final levelTitles = [
      'Rookie', 'Junior Dev', 'Developer', 'Senior Dev',
      'Lead Dev', 'Architect', 'Principal', 'Distinguished', 'Fellow'
    ];
    final levelEmojis = ['🐣', '💻', '⚡', '🔥', '🚀', '🏗️', '⭐', '👑', '🌟'];

    int prevLevel = 0;
    int newLevel  = 0;
    for (int i = 0; i < levels.length; i++) {
      if (prevXP >= levels[i]) prevLevel = i;
      if (newXP  >= levels[i]) newLevel  = i;
    }

    if (newLevel > prevLevel) {
      _ref.read(notifControllerProvider).levelUp(
        levelTitles[newLevel],
        levelEmojis[newLevel],
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Screen
// ═══════════════════════════════════════════════════════════════════
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _selectedCategory = 'all';

  static const _categories = [
    ('all',       '🏆', 'All'),
    ('projects',  '📁', 'Projects'),
    ('skills',    '🧠', 'Skills'),
    ('interview', '💼', 'Interview'),
    ('journal',   '📔', 'Journal'),
    ('snippets',  '💾', 'Snippets'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final totalXP   = ref.watch(totalXPProvider);
    final levelData = ref.watch(developerLevelProvider);

    final unlockedIds = unlockedAsync.asData?.value
        .map((u) => u.achievementId).toSet() ?? {};

    final filtered = _selectedCategory == 'all'
        ? AchievementsData.all
        : AchievementsData.byCategory(_selectedCategory);

    final unlockedCount = filtered.where((a) => unlockedIds.contains(a.id)).length;

    return SafeArea(
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('// developer rank',
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                Text('Achievements',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.white : AppTheme.black)),
              ]),
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [
                    Colors.amber.withOpacity(0.3),
                    Colors.orange.withOpacity(0.2),
                  ]),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(children: [
                  Text(levelData['emoji'] as String, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Lv.${levelData['level']}',
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    Text(levelData['title'] as String,
                        style: const TextStyle(fontFamily: 'Syne', fontSize: 12,
                            fontWeight: FontWeight.w800, color: Colors.amber)),
                  ]),
                ]),
              ),
            ]),

            const SizedBox(height: 16),

            // XP Bar
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    const Text('⚡ ', style: TextStyle(fontSize: 16)),
                    Text('$totalXP XP',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                  ]),
                  Text('${unlockedIds.length}/${AchievementsData.all.length} unlocked',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (levelData['progress'] as double).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$totalXP XP',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('${levelData['nextXP']} XP → Next Level',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ]),
              ]),
            ),
          ]).animate().fadeIn(),
        ),

        const SizedBox(height: 12),

        // Category filter
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isSelected
                        ? (isDark ? AppTheme.white : AppTheme.black)
                        : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                    border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    Text(cat.$2, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(cat.$3,
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (isDark ? AppTheme.black : AppTheme.white)
                                : (isDark ? AppTheme.silver : AppTheme.gray))),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),

        // Progress text
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$unlockedCount / ${filtered.length}',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            Text('${filtered.isEmpty ? 0 : (unlockedCount / filtered.length * 100).round()}% complete',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.white : AppTheme.black)),
          ]),
        ),

        // Grid
        Expanded(
          child: unlockedAsync.when(
            loading: () => Center(child: CircularProgressIndicator(
                color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (_) => GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 1.1,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final a = filtered[i];
                final isUnlocked = unlockedIds.contains(a.id);
                final unlockedAt = unlockedAsync.asData?.value
                    .firstWhere((u) => u.achievementId == a.id,
                        orElse: () => UnlockedAchievement(achievementId: '', unlockedAt: DateTime.now()))
                    .unlockedAt;
                return _AchievementCard(
                  achievement: a, isUnlocked: isUnlocked,
                  unlockedAt: isUnlocked ? unlockedAt : null,
                  isDark: isDark, index: i,
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 8),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Achievement Card
// ═══════════════════════════════════════════════════════════════════
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isDark;
  final int index;

  const _AchievementCard({
    required this.achievement, required this.isUnlocked,
    this.unlockedAt, required this.isDark, required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.center, children: [
          AnimatedOpacity(
            opacity: isUnlocked ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Text(achievement.emoji, style: const TextStyle(fontSize: 36)),
          ),
          if (!isUnlocked)
            Text('🔒', style: TextStyle(fontSize: 28,
                color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.25))),
        ]),

        const SizedBox(height: 5),

        Text(achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Syne', fontSize: 12, fontWeight: FontWeight.w700,
              color: isUnlocked
                  ? (isDark ? AppTheme.white : AppTheme.black)
                  : (isDark ? AppTheme.gray : AppTheme.lightGray),
            )),

        const SizedBox(height: 3),

        Text(achievement.description,
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, height: 1.2,
                color: isDark ? AppTheme.gray : AppTheme.lightGray)),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isUnlocked
                ? Colors.amber.withOpacity(0.2)
                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05),
            border: Border.all(
                color: isUnlocked
                    ? Colors.amber.withOpacity(0.4)
                    : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
          ),
          child: Text(
            isUnlocked ? '⚡ +${achievement.xpReward} XP' : '${achievement.xpReward} XP',
            style: TextStyle(
              fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w700,
              color: isUnlocked ? Colors.amber : (isDark ? AppTheme.gray : AppTheme.lightGray),
            ),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30));
  }
}
