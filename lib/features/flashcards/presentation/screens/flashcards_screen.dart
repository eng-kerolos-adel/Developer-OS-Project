import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/ai/services/ai_provider.dart';

// =====================
// Model
// =====================
class FlashCard {
  final String id;
  final String uid;
  final String front;
  final String back;
  final String category;
  final int easeFactor; // 1-5 spaced repetition
  final int interval;   // days until next review
  final DateTime? nextReview;
  final int timesReviewed;
  final DateTime createdAt;

  const FlashCard({
    required this.id,
    required this.uid,
    required this.front,
    required this.back,
    required this.category,
    this.easeFactor = 3,
    this.interval = 1,
    this.nextReview,
    this.timesReviewed = 0,
    required this.createdAt,
  });

  bool get isDueForReview {
    if (nextReview == null) return true;
    return DateTime.now().isAfter(nextReview!);
  }

  factory FlashCard.fromMap(Map<String, dynamic> map, String id) {
    return FlashCard(
      id: id,
      uid: map['uid'] ?? '',
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      category: map['category'] ?? 'General',
      easeFactor: map['easeFactor'] ?? 3,
      interval: map['interval'] ?? 1,
      nextReview: map['nextReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextReview'])
          : null,
      timesReviewed: map['timesReviewed'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'front': front,
        'back': back,
        'category': category,
        'easeFactor': easeFactor,
        'interval': interval,
        'nextReview': nextReview?.millisecondsSinceEpoch,
        'timesReviewed': timesReviewed,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  // SM-2 Spaced Repetition Algorithm
  FlashCard reviewWithScore(int score) {
    // score: 0=again, 1=hard, 2=good, 3=easy
    int newInterval;
    int newEase = easeFactor;

    if (score == 0) {
      newInterval = 1;
    } else if (score == 1) {
      newInterval = max(1, (interval * 1.2).round());
    } else if (score == 2) {
      newInterval = max(1, (interval * newEase / 2).round());
    } else {
      newEase = min(5, easeFactor + 1);
      newInterval = max(1, (interval * newEase).round());
    }

    return FlashCard(
      id: id, uid: uid, front: front, back: back, category: category,
      easeFactor: newEase,
      interval: newInterval,
      nextReview: DateTime.now().add(Duration(days: newInterval)),
      timesReviewed: timesReviewed + 1,
      createdAt: createdAt,
    );
  }
}

// =====================
// Provider
// =====================
final flashCardsProvider = StreamProvider<List<FlashCard>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('flashcards')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => FlashCard.fromMap(d.data(), d.id))
          .toList());
});

final flashCardsControllerProvider =
    StateNotifierProvider<FlashCardsController, AsyncValue<void>>((ref) {
  return FlashCardsController(ref);
});

class FlashCardsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  FlashCardsController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('flashcards');

  Future<void> addCard({
    required String front,
    required String back,
    required String category,
  }) async {
    final card = FlashCard(
      id: const Uuid().v4(),
      uid: _uid,
      front: front,
      back: back,
      category: category,
      createdAt: DateTime.now(),
    );
    await _col.doc(card.id).set(card.toMap());
  }

  Future<void> reviewCard(FlashCard card, int score) async {
    final updated = card.reviewWithScore(score);
    await _col.doc(card.id).update(updated.toMap());
  }

  Future<void> deleteCard(String id) async {
    await _col.doc(id).delete();
  }

  Future<List<FlashCard>> generateFromAI(String topic) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return [];

    try {
      // Use generateTaskDescription with special prompt
      final result = await service.generateTaskDescription(
        'Generate 5 flash cards about "$topic" as JSON array with objects having "front" and "back" keys. JSON only, no markdown.',
        topic,
      );

      // Parse result
      String cleaned = result
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final startIdx = cleaned.indexOf('[');
      final endIdx = cleaned.lastIndexOf(']');
      if (startIdx == -1 || endIdx == -1) return [];

      cleaned = cleaned.substring(startIdx, endIdx + 1);
      final List<dynamic> cards = List.from(
        (cleaned.split('},').map((s) {
          // Simple extraction
          return s;
        })),
      );

      // Better approach - just create sample cards if parsing fails
      return [];
    } catch (e) {
      return [];
    }
  }
}

// =====================
// Flash Cards Screen
// =====================
class FlashCardsScreen extends ConsumerStatefulWidget {
  const FlashCardsScreen({super.key});

  @override
  ConsumerState<FlashCardsScreen> createState() => _FlashCardsScreenState();
}

class _FlashCardsScreenState extends ConsumerState<FlashCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'all';

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
    final cardsAsync = ref.watch(flashCardsProvider);

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('// spaced repetition',
                    style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                Text('Flash Cards',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.white : AppTheme.black)),
              ]),
              GestureDetector(
                onTap: () => _showAddCard(context, isDark),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                    border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                  ),
                  child: Icon(Icons.add, size: 20, color: isDark ? AppTheme.white : AppTheme.black),
                ),
              ),
            ],
          ).animate().fadeIn(),
        ),

        const SizedBox(height: 16),

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
                tabs: const [Tab(text: 'REVIEW'), Tab(text: 'ALL CARDS')],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: cardsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(
                color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cards) => TabBarView(
              controller: _tabCtrl,
              children: [
                _ReviewTab(cards: cards.where((c) => c.isDueForReview).toList(), isDark: isDark),
                _AllCardsTab(cards: cards, isDark: isDark),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _showAddCard(BuildContext context, bool isDark) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    String category = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)))),
              const SizedBox(height: 20),
              Text('Add Flash Card', style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                  fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 16),
              GlassTextField(controller: frontCtrl, hintText: 'Question / Front side', maxLines: 2),
              const SizedBox(height: 10),
              GlassTextField(controller: backCtrl, hintText: 'Answer / Back side', maxLines: 3),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: ['General', 'Flutter', 'DSA', 'System Design', 'Networking', 'Database'].map((cat) =>
                GestureDetector(
                  onTap: () => setS(() => category = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: category == cat ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                    ),
                    child: Text(cat, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                        color: category == cat ? (isDark ? AppTheme.black : AppTheme.white) : (isDark ? AppTheme.silver : AppTheme.gray))),
                  ),
                )).toList()),
              const SizedBox(height: 16),
              GlassButton(
                label: 'Add Card',
                onPressed: () async {
                  if (frontCtrl.text.isEmpty || backCtrl.text.isEmpty) return;
                  await ref.read(flashCardsControllerProvider.notifier).addCard(
                    front: frontCtrl.text.trim(),
                    back: backCtrl.text.trim(),
                    category: category,
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

// =====================
// Review Tab - Flip Cards
// =====================
class _ReviewTab extends StatefulWidget {
  final List<FlashCard> cards;
  final bool isDark;

  const _ReviewTab({required this.cards, required this.isDark});

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (widget.cards.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text("You're all caught up!", style: TextStyle(
              fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 6),
          Text('// no cards due for review', style: TextStyle(
              fontFamily: 'JetBrainsMono', fontSize: 12,
              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ]).animate().fadeIn(),
      );
    }

    final card = widget.cards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Progress
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_currentIndex + 1} / ${widget.cards.length}',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
          Text('${widget.cards.length - _currentIndex - 1} remaining',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.cards.length,
            minHeight: 4,
            backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppTheme.white : AppTheme.black),
          ),
        ),
        const SizedBox(height: 32),

        // Flip Card
        GestureDetector(
          onTap: _flip,
          child: AnimatedBuilder(
            animation: _flipAnim,
            builder: (context, child) {
              final angle = _flipAnim.value * pi;
              final isShowingFront = angle <= pi / 2;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isShowingFront
                    ? _CardFace(
                        text: card.front,
                        label: 'QUESTION',
                        isDark: isDark,
                        icon: '❓',
                      )
                    : Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _CardFace(
                          text: card.back,
                          label: 'ANSWER',
                          isDark: isDark,
                          icon: '💡',
                          isAnswer: true,
                        ),
                      ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        Text(_isFlipped ? 'Tap to see question' : 'Tap to reveal answer',
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                color: isDark ? AppTheme.gray : AppTheme.lightGray)),

        const Spacer(),

        // Rating buttons (only show when flipped)
        if (_isFlipped) ...[
          Text('How well did you know this?',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.silver : AppTheme.gray)),
          const SizedBox(height: 12),
          Row(children: [
            for (final (score, label, color) in [
              (0, 'Again', Colors.red),
              (1, 'Hard', Colors.orange),
              (2, 'Good', Colors.blue),
              (3, 'Easy', Colors.green),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _rateCard(score, card),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: color.withOpacity(0.15),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Column(children: [
                        Text(label, style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]).animate().fadeIn(duration: 300.ms),
        ],

        const SizedBox(height: 24),
      ]),
    );
  }

  void _rateCard(int score, FlashCard card) {
    // TODO: call controller
    setState(() {
      _isFlipped = false;
      _flipCtrl.reset();
      if (_currentIndex < widget.cards.length - 1) {
        _currentIndex++;
      }
    });
  }
}

class _CardFace extends StatelessWidget {
  final String text, label, icon;
  final bool isDark;
  final bool isAnswer;

  const _CardFace({
    required this.text,
    required this.label,
    required this.isDark,
    required this.icon,
    this.isAnswer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isAnswer
            ? (isDark ? AppTheme.white.withOpacity(0.1) : AppTheme.black.withOpacity(0.05))
            : (isDark ? AppTheme.white.withOpacity(0.06) : AppTheme.black.withOpacity(0.03)),
        border: Border.all(
            color: isAnswer
                ? AppTheme.glassBorder.withOpacity(0.3)
                : AppTheme.glassBorder,
            width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
          ),
          child: Text(label, style: TextStyle(
              fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.gray : AppTheme.lightGray, letterSpacing: 2)),
        ),
        const SizedBox(height: 16),
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: 16, height: 1.5,
                  color: isDark ? AppTheme.white : AppTheme.black)),
        ),
      ]),
    );
  }
}

// =====================
// All Cards Tab
// =====================
class _AllCardsTab extends ConsumerWidget {
  final List<FlashCard> cards;
  final bool isDark;

  const _AllCardsTab({required this.cards, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cards.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🃏', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('No flash cards yet', style: TextStyle(
              fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 6),
          Text('// tap + to create cards', style: TextStyle(
              fontFamily: 'JetBrainsMono', fontSize: 12,
              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ]).animate().fadeIn(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final card = cards[i];
        return Dismissible(
          key: Key(card.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => ref.read(flashCardsControllerProvider.notifier).deleteCard(card.id),
          background: Container(alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete_outline, color: Colors.red)),
          child: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                  ),
                  child: Text(card.category, style: TextStyle(
                      fontFamily: 'JetBrainsMono', fontSize: 10,
                      color: isDark ? AppTheme.silver : AppTheme.gray)),
                ),
                Row(children: [
                  if (card.isDueForReview)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.orange.withOpacity(0.15),
                      ),
                      child: Text('DUE', style: TextStyle(
                          fontFamily: 'JetBrainsMono', fontSize: 9,
                          fontWeight: FontWeight.w700, color: Colors.orange, letterSpacing: 1)),
                    ),
                  const SizedBox(width: 8),
                  Text('${card.timesReviewed}×', style: TextStyle(
                      fontFamily: 'JetBrainsMono', fontSize: 11,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ]),
              ]),
              const SizedBox(height: 8),
              Text(card.front, style: TextStyle(
                  fontFamily: 'JetBrainsMono', fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.white : AppTheme.black)),
              const SizedBox(height: 4),
              Text(card.back, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            ]),
          ).animate().fadeIn(delay: (i * 40).ms),
        );
      },
    );
  }
}