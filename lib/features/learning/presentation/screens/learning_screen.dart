import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';

// =====================
// Models
// =====================
class LearningResource {
  final String id;
  final String uid;
  final String title;
  final String type; // 'book', 'course', 'video', 'article', 'podcast'
  final String? author;
  final String? url;
  final String? platform; // 'Udemy', 'YouTube', 'Book', etc.
  final int progressPercent; // 0-100
  final String status; // 'want', 'reading', 'completed'
  final double? rating; // 1-5
  final String? notes;
  final List<String> tags;
  final DateTime addedAt;
  final DateTime? completedAt;

  const LearningResource({
    required this.id,
    required this.uid,
    required this.title,
    required this.type,
    this.author,
    this.url,
    this.platform,
    this.progressPercent = 0,
    this.status = 'want',
    this.rating,
    this.notes,
    this.tags = const [],
    required this.addedAt,
    this.completedAt,
  });

  String get typeEmoji {
    switch (type) {
      case 'book': return '📚';
      case 'course': return '🎓';
      case 'video': return '▶️';
      case 'article': return '📄';
      case 'podcast': return '🎧';
      default: return '📖';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'want': return 'Want to Learn';
      case 'reading': return 'In Progress';
      case 'completed': return 'Completed';
      default: return status;
    }
  }

  factory LearningResource.fromMap(Map<String, dynamic> map, String id) {
    return LearningResource(
      id: id,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'book',
      author: map['author'],
      url: map['url'],
      platform: map['platform'],
      progressPercent: map['progressPercent'] ?? 0,
      status: map['status'] ?? 'want',
      rating: map['rating']?.toDouble(),
      notes: map['notes'],
      tags: List<String>.from(map['tags'] ?? []),
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['addedAt'])
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'title': title,
        'type': type,
        'author': author,
        'url': url,
        'platform': platform,
        'progressPercent': progressPercent,
        'status': status,
        'rating': rating,
        'notes': notes,
        'tags': tags,
        'addedAt': addedAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
      };

  LearningResource copyWith({
    int? progressPercent,
    String? status,
    double? rating,
    String? notes,
    DateTime? completedAt,
  }) {
    return LearningResource(
      id: id, uid: uid, title: title, type: type,
      author: author, url: url, platform: platform,
      progressPercent: progressPercent ?? this.progressPercent,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      tags: tags,
      addedAt: addedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// Learning Path Step
class LearningPathStep {
  final String title;
  final String description;
  final List<String> resources;
  final String estimatedTime;
  final bool isOptional;

  const LearningPathStep({
    required this.title,
    required this.description,
    this.resources = const [],
    this.estimatedTime = '1 week',
    this.isOptional = false,
  });
}

// =====================
// Provider
// =====================
final learningResourcesProvider = StreamProvider<List<LearningResource>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('learning')
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => LearningResource.fromMap(d.data(), d.id))
          .toList());
});

final learningControllerProvider =
    StateNotifierProvider<LearningController, AsyncValue<void>>((ref) {
  return LearningController(ref);
});

class LearningController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  LearningController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users').doc(_uid).collection('learning');

  Future<void> addResource({
    required String title,
    required String type,
    String? author,
    String? url,
    String? platform,
    List<String> tags = const [],
  }) async {
    final resource = LearningResource(
      id: const Uuid().v4(),
      uid: _uid,
      title: title,
      type: type,
      author: author,
      url: url,
      platform: platform,
      tags: tags,
      addedAt: DateTime.now(),
    );
    await _col.doc(resource.id).set(resource.toMap());
  }

  Future<void> updateProgress(LearningResource resource, int progress) async {
    String newStatus = resource.status;
    DateTime? completedAt;

    if (progress == 100) {
      newStatus = 'completed';
      completedAt = DateTime.now();
    } else if (progress > 0) {
      newStatus = 'reading';
    }

    await _col.doc(resource.id).update({
      'progressPercent': progress,
      'status': newStatus,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    });
  }

  Future<void> rateResource(LearningResource resource, double rating) async {
    await _col.doc(resource.id).update({'rating': rating});
  }

  Future<void> deleteResource(String id) async {
    await _col.doc(id).delete();
  }
}

// =====================
// Learning Screen
// =====================
class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filterStatus = 'all';

  static const _statuses = [
    ('all', 'All'),
    ('reading', 'In Progress'),
    ('want', 'Want'),
    ('completed', 'Done'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resourcesAsync = ref.watch(learningResourcesProvider);

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
                  Text('// knowledge base',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Learning Hub',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ]),
                GestureDetector(
                  onTap: () => _showAddResource(context, isDark),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                      border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                    ),
                    child: Icon(Icons.add, size: 20,
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
                controller: _tabCtrl,
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
                  Tab(text: 'LIBRARY'),
                  Tab(text: 'ROADMAPS'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Library Tab
                Column(
                  children: [
                    // Stats + filter
                    resourcesAsync.when(
                      data: (resources) => Column(children: [
                        // Stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(children: [
                            _MiniStat(
                                value: '${resources.where((r) => r.status == 'completed').length}',
                                label: 'Done', color: Colors.green, isDark: isDark),
                            const SizedBox(width: 10),
                            _MiniStat(
                                value: '${resources.where((r) => r.status == 'reading').length}',
                                label: 'Active', color: Colors.blue, isDark: isDark),
                            const SizedBox(width: 10),
                            _MiniStat(
                                value: '${resources.where((r) => r.status == 'want').length}',
                                label: 'Wishlist', color: Colors.orange, isDark: isDark),
                            const SizedBox(width: 10),
                            _MiniStat(
                                value: '${resources.length}',
                                label: 'Total', color: isDark ? AppTheme.white : AppTheme.black,
                                isDark: isDark),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        // Filter chips
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: _statuses.map((s) {
                              final selected = _filterStatus == s.$1;
                              return GestureDetector(
                                onTap: () => setState(() => _filterStatus = s.$1),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: selected
                                        ? (isDark ? AppTheme.white : AppTheme.black)
                                        : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                                    border: Border.all(color: selected
                                        ? Colors.transparent
                                        : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                                  ),
                                  child: Text(s.$2,
                                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? (isDark ? AppTheme.black : AppTheme.white)
                                              : (isDark ? AppTheme.silver : AppTheme.gray))),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: resourcesAsync.when(
                        loading: () => Center(child: CircularProgressIndicator(
                            color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (resources) {
                          final filtered = _filterStatus == 'all'
                              ? resources
                              : resources.where((r) => r.status == _filterStatus).toList();

                          if (filtered.isEmpty) {
                            return Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('📚', style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 16),
                                  Text('Nothing here yet',
                                      style: TextStyle(fontFamily: 'Syne', fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppTheme.white : AppTheme.black)),
                                  const SizedBox(height: 6),
                                  Text('// add books, courses, videos',
                                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                                ]).animate().fadeIn());
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final r = filtered[i];
                              return _ResourceCard(resource: r, isDark: isDark, index: i);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Roadmaps Tab
                _RoadmapsTab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResource(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String type = 'book';
    String platform = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)))),
                const SizedBox(height: 20),
                Text('Add Resource', style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                    fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
                const SizedBox(height: 16),

                // Type selector
                Row(children: [
                  for (final (t, emoji) in [
                    ('book', '📚'), ('course', '🎓'), ('video', '▶️'),
                    ('article', '📄'), ('podcast', '🎧'),
                  ])
                    Expanded(child: GestureDetector(
                      onTap: () => setS(() => type = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: type == t
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        ),
                        child: Column(children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          Text(t, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8,
                              color: type == t ? (isDark ? AppTheme.black : AppTheme.white) : (isDark ? AppTheme.gray : AppTheme.lightGray))),
                        ]),
                      ),
                    )),
                ]),

                const SizedBox(height: 14),
                GlassTextField(controller: titleCtrl, hintText: 'Title'),
                const SizedBox(height: 10),
                GlassTextField(controller: authorCtrl, hintText: 'Author / Creator (optional)'),
                const SizedBox(height: 10),
                GlassTextField(controller: urlCtrl, hintText: 'URL (optional)',
                    keyboardType: TextInputType.url),
                const SizedBox(height: 16),
                GlassButton(
                  label: 'Add to Library',
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await ref.read(learningControllerProvider.notifier).addResource(
                      title: titleCtrl.text.trim(),
                      type: type,
                      author: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                      url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// =====================
// Resource Card
// =====================
class _ResourceCard extends ConsumerStatefulWidget {
  final LearningResource resource;
  final bool isDark;
  final int index;

  const _ResourceCard({required this.resource, required this.isDark, required this.index});

  @override
  ConsumerState<_ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends ConsumerState<_ResourceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;
    final isDark = widget.isDark;

    return Dismissible(
      key: Key(r.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(learningControllerProvider.notifier).deleteResource(r.id),
      background: Container(alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete_outline, color: Colors.red)),
      child: GlassCard(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(r.typeEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black)),
              if (r.author != null)
                Text(r.author!, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            ])),
            _StatusBadge(status: r.status, isDark: isDark),
          ]),

          if (r.progressPercent > 0 || r.status == 'reading') ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
              Text('${r.progressPercent}%', style: TextStyle(fontFamily: 'JetBrainsMono',
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: r.progressPercent / 100,
                minHeight: 5,
                backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                    r.status == 'completed' ? Colors.green : Colors.blue),
              )),
          ],

          if (_expanded) ...[
            const SizedBox(height: 12),
            // Progress slider
            Text('Update Progress:', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                color: isDark ? AppTheme.silver : AppTheme.gray)),
            Slider(
              value: r.progressPercent.toDouble(),
              min: 0, max: 100, divisions: 20,
              activeColor: isDark ? AppTheme.white : AppTheme.black,
              inactiveColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
              onChanged: (v) => ref.read(learningControllerProvider.notifier)
                  .updateProgress(r, v.round()),
            ),

            // Rating
            if (r.status == 'completed') ...[
              Text('Rating:', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                  color: isDark ? AppTheme.silver : AppTheme.gray)),
              const SizedBox(height: 6),
              Row(children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => ref.read(learningControllerProvider.notifier)
                      .rateResource(r, (i + 1).toDouble()),
                  child: Icon(
                    i < (r.rating ?? 0) ? Icons.star : Icons.star_outline,
                    size: 28, color: Colors.amber,
                  ),
                );
              })),
            ],

            if (r.url != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(r.url!),
                    mode: LaunchMode.externalApplication),
                child: Row(children: [
                  Icon(Icons.open_in_new, size: 13,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray),
                  const SizedBox(width: 6),
                  Text('Open Resource', style: TextStyle(fontFamily: 'JetBrainsMono',
                      fontSize: 12, color: isDark ? AppTheme.silver : AppTheme.gray)),
                ]),
              ),
            ],
          ],
        ]),
      ).animate().fadeIn(delay: (widget.index * 50).ms),
    );
  }
}

// =====================
// Roadmaps Tab
// =====================
class _RoadmapsTab extends ConsumerWidget {
  final bool isDark;
  const _RoadmapsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final specialization = profile?.specialization ?? 'Full Stack Developer';
    final roadmap = _getRoadmap(specialization);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text('🗺️', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Learning Path', style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black)),
              Text('Based on: $specialization', style: TextStyle(fontFamily: 'JetBrainsMono',
                  fontSize: 11, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            ])),
          ]),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        ...roadmap.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                    border: Border.all(
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)),
                  ),
                  child: Center(child: Text('${i + 1}',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black))),
                ),
                if (i < roadmap.length - 1)
                  Container(width: 2, height: 40,
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
              ]),
              const SizedBox(width: 12),
              Expanded(child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(step.title,
                        style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black))),
                    if (step.isOptional)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                            color: Colors.orange.withOpacity(0.15)),
                        child: Text('OPTIONAL', style: TextStyle(fontFamily: 'JetBrainsMono',
                            fontSize: 8, color: Colors.orange, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 4),
                  Text(step.description, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray, height: 1.5)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.access_time, size: 12,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray),
                    const SizedBox(width: 4),
                    Text(step.estimatedTime, style: TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 10, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  ]),
                  if (step.resources.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4,
                      children: step.resources.map((r) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        ),
                        child: Text(r, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                            color: isDark ? AppTheme.silver : AppTheme.gray)),
                      )).toList()),
                  ],
                ]),
              )),
            ]),
          ).animate().fadeIn(delay: (i * 60).ms);
        }),

        const SizedBox(height: 32),
      ],
    );
  }

  List<LearningPathStep> _getRoadmap(String specialization) {
    if (specialization.contains('Flutter') || specialization.contains('Mobile')) {
      return [
        LearningPathStep(title: 'Dart Fundamentals',
            description: 'Master Dart syntax, OOP, async/await, and null safety.',
            resources: ['Dart.dev Tour', 'Effective Dart'], estimatedTime: '2 weeks'),
        LearningPathStep(title: 'Flutter Basics',
            description: 'Widgets, layouts, state, navigation, and theming.',
            resources: ['Flutter Docs', 'Widget Catalog'], estimatedTime: '3 weeks'),
        LearningPathStep(title: 'State Management',
            description: 'Learn Riverpod, Provider, or Bloc for scalable apps.',
            resources: ['Riverpod Docs', 'Flutter Bloc'], estimatedTime: '2 weeks'),
        LearningPathStep(title: 'Backend Integration',
            description: 'REST APIs, Firebase, Firestore, authentication.',
            resources: ['Firebase Docs', 'dio package'], estimatedTime: '2 weeks'),
        LearningPathStep(title: 'Advanced Flutter',
            description: 'Custom animations, platform channels, performance.',
            resources: ['Flutter Deep Dives'], estimatedTime: '3 weeks'),
        LearningPathStep(title: 'Testing & CI/CD',
            description: 'Unit, widget, integration tests. GitHub Actions.',
            resources: ['Flutter Testing Guide'], estimatedTime: '2 weeks', isOptional: true),
        LearningPathStep(title: 'App Store Publishing',
            description: 'Play Store & App Store deployment.',
            resources: ['Store Guidelines'], estimatedTime: '1 week'),
      ];
    }

    if (specialization.contains('Backend') || specialization.contains('Full Stack')) {
      return [
        LearningPathStep(title: 'Programming Fundamentals',
            description: 'Data structures, algorithms, and CS basics.',
            resources: ['CS50', 'CLRS Book'], estimatedTime: '4 weeks'),
        LearningPathStep(title: 'Backend Framework',
            description: 'Node.js/Express, Django, or Spring Boot.',
            resources: ['Official Docs', 'FreeCodeCamp'], estimatedTime: '3 weeks'),
        LearningPathStep(title: 'Databases',
            description: 'SQL (PostgreSQL), NoSQL (MongoDB), Redis.',
            resources: ['PostgreSQL Docs', 'MongoDB University'], estimatedTime: '2 weeks'),
        LearningPathStep(title: 'APIs & Authentication',
            description: 'REST, GraphQL, JWT, OAuth 2.0.',
            resources: ['REST API Design', 'OAuth Guide'], estimatedTime: '2 weeks'),
        LearningPathStep(title: 'System Design',
            description: 'Scalability, caching, load balancing, microservices.',
            resources: ['System Design Primer', 'Designing Data-Intensive Apps'], estimatedTime: '4 weeks'),
        LearningPathStep(title: 'DevOps & Cloud',
            description: 'Docker, Kubernetes, AWS/GCP, CI/CD.',
            resources: ['Docker Docs', 'AWS Free Tier'], estimatedTime: '3 weeks', isOptional: true),
      ];
    }

    // Default path
    return [
      LearningPathStep(title: 'Core Programming',
          description: 'Choose a language and master it completely.',
          resources: ['The Odin Project', 'CS50'], estimatedTime: '4 weeks'),
      LearningPathStep(title: 'Web Fundamentals',
          description: 'HTML, CSS, JavaScript essentials.',
          resources: ['MDN Web Docs', 'freeCodeCamp'], estimatedTime: '3 weeks'),
      LearningPathStep(title: 'Version Control',
          description: 'Git, GitHub, branching, pull requests.',
          resources: ['Pro Git Book', 'GitHub Docs'], estimatedTime: '1 week'),
      LearningPathStep(title: 'Databases',
          description: 'SQL fundamentals and one NoSQL database.',
          resources: ['SQLBolt', 'MongoDB University'], estimatedTime: '2 weeks'),
      LearningPathStep(title: 'Build Projects',
          description: 'Create 3-5 real projects for your portfolio.',
          resources: ['Frontend Mentor', 'The Odin Project'], estimatedTime: '4 weeks'),
    ];
  }
}

// =====================
// Helper Widgets
// =====================
class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool isDark;

  const _MiniStat({required this.value, required this.label,
      required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 18,
            fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed': color = Colors.green; break;
      case 'reading': color = Colors.blue; break;
      default: color = Colors.orange;
    }

    final label = status == 'completed' ? 'DONE'
        : status == 'reading' ? 'ACTIVE' : 'WANT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontFamily: 'JetBrainsMono',
          fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
    );
  }
}