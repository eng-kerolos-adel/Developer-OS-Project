// lib/features/notifications/providers/notification_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/notifications/domain/models/notification_models.dart';
import 'package:developer_os/features/notifications/services/push_notification_service.dart';

// ═══════════════════════════════════════════════════════════════════
// Stream
// ═══════════════════════════════════════════════════════════════════
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('notifications')
      .where('isDismissed', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => AppNotification.fromMap(d.data(), d.id)).toList());
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).asData?.value
      .where((n) => !n.isRead).length ?? 0;
});

// ═══════════════════════════════════════════════════════════════════
// Settings
// ═══════════════════════════════════════════════════════════════════
final notifSettingsProvider =
    StateNotifierProvider<NotifSettingsNotifier, NotifSettings>((ref) {
  return NotifSettingsNotifier(ref);
});

class NotifSettingsNotifier extends StateNotifier<NotifSettings> {
  final Ref _ref;
  NotifSettingsNotifier(this._ref) : super(const NotifSettings()) { _load(); }

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = doc.data()?['notifSettings'];
      if (data != null && mounted) {
        state = NotifSettings.fromMap(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
  }

  Future<void> update(NotifSettings s) async {
    state = s;
    if (_uid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(_uid)
        .set({'notifSettings': s.toMap()}, SetOptions(merge: true));
  }
}

// ═══════════════════════════════════════════════════════════════════
// Controller
// ═══════════════════════════════════════════════════════════════════
final notifControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(ref);
});

class NotificationController {
  final Ref _ref;
  NotificationController(this._ref);

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';
  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users').doc(_uid).collection('notifications');

  bool _isEnabled(NotifType type) {
    final s = _ref.read(notifSettingsProvider);
    if (!s.enabled) return false;
    switch (type) {
      case NotifType.taskDue:
      case NotifType.taskOverdue:
      case NotifType.projectDeadline:
      case NotifType.projectMilestone:
      case NotifType.projectCompleted:
        return s.taskReminders;
      case NotifType.flashcardReview:
      case NotifType.learningGoal:
        return s.flashcardReminders;
      case NotifType.invoiceDue:
      case NotifType.invoiceOverdue:
      case NotifType.paymentReceived:
        return s.invoiceAlerts;
      case NotifType.achievementUnlocked:
      case NotifType.achievementLocked:
      case NotifType.levelUp:
      case NotifType.xpMilestone:
        return s.achievementAlerts;
      case NotifType.journalReminder:
        return s.journalReminders;
      default:
        return true;
    }
  }

  Future<void> push({
    required NotifType type,
    required String title,
    required String body,
    required String emoji,
    NotifPriority priority = NotifPriority.normal,
    Map<String, dynamic> payload = const {},
  }) async {
    if (!_isEnabled(type)) return;
    if (_uid.isEmpty) return;

    final notif = AppNotification(
      id: const Uuid().v4(), uid: _uid, type: type,
      title: title, body: body, emoji: emoji,
      createdAt: DateTime.now(), priority: priority, payload: payload,
    );

    await _col.doc(notif.id).set(notif.toMap());

    await PushNotificationService.showLocalNotification(
      title: '$emoji $title',
      body: body,
      payload: '{"type":"${type.name}","id":"${notif.id}"}',
      isUrgent: priority == NotifPriority.urgent || priority == NotifPriority.high,
    );
  }

  Future<void> markRead(String id) => _col.doc(id).update({'isRead': true});

  Future<void> markAllRead() async {
    final snap = await _col.where('isRead', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.update(d.reference, {'isRead': true});
    await batch.commit();
  }

  Future<void> dismiss(String id) => _col.doc(id).update({'isDismissed': true});

  Future<void> dismissAll() async {
    final snap = await _col.get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) batch.update(d.reference, {'isDismissed': true});
    await batch.commit();
  }

  // ── Factories ─────────────────────────────────────────────────────

  Future<void> taskDue(String task, String project) => push(
    type: NotifType.taskDue, emoji: '📋',
    title: 'Task Due Today',
    body: '"$task" in $project is due today.',
    priority: NotifPriority.high,
    payload: {'project': project, 'task': task},
  );

  Future<void> taskOverdue(String task, int daysLate, String project) => push(
    type: NotifType.taskOverdue, emoji: '⚠️',
    title: 'Task Overdue',
    body: '"$task" is $daysLate day${daysLate > 1 ? 's' : ''} overdue in $project.',
    priority: NotifPriority.urgent,
    payload: {'task': task, 'daysLate': daysLate},
  );

  Future<void> projectCompleted(String name) => push(
    type: NotifType.projectCompleted, emoji: '🎉',
    title: 'Project Shipped! 🎉',
    body: '"$name" is complete. Add it to your portfolio and celebrate!',
    priority: NotifPriority.high,
  );

  Future<void> projectDeadline(String name, int daysLeft) => push(
    type: NotifType.projectDeadline, emoji: '🗓️',
    title: 'Deadline Approaching',
    body: '"$name" is due in $daysLeft day${daysLeft > 1 ? 's' : ''}.',
    priority: NotifPriority.high,
  );

  Future<void> projectMilestone(String project, String milestone) => push(
    type: NotifType.projectMilestone, emoji: '🚩',
    title: 'Milestone Reached!',
    body: '"$milestone" completed in $project.',
  );

  Future<void> streakAchieved(int days) => push(
    type: NotifType.streakAchieved, emoji: '🔥',
    title: '$days-Day Streak! 🔥',
    body: '$days consecutive days of coding. You are unstoppable!',
    priority: NotifPriority.high,
  );

  Future<void> codingGoal(int hours, int targetHours) => push(
    type: NotifType.codingGoal, emoji: '🎯',
    title: 'Daily Coding Goal Hit!',
    body: 'You hit your ${targetHours}h target — ${hours}h coded today.',
  );

  Future<void> flashcardReview(int count) => push(
    type: NotifType.flashcardReview, emoji: '🃏',
    title: 'Cards Due for Review!',
    body: '$count flashcard${count > 1 ? 's' : ''} waiting. Keep your memory sharp.',
    payload: {'count': count},
  );

  Future<void> courseCompleted(String title) => push(
    type: NotifType.learningGoal, emoji: '🎓',
    title: 'Course Completed!',
    body: 'You finished "$title". Add it to your profile certificates!',
    priority: NotifPriority.high,
  );

  Future<void> invoiceDue(String client, String amount, int days) => push(
    type: NotifType.invoiceDue, emoji: '🧾',
    title: 'Invoice Due in $days Day${days > 1 ? 's' : ''}',
    body: '$amount from $client. Send a reminder if needed.',
    priority: NotifPriority.high,
    payload: {'client': client, 'amount': amount},
  );

  Future<void> invoiceOverdue(String client, String amount) => push(
    type: NotifType.invoiceOverdue, emoji: '💸',
    title: 'Invoice Overdue!',
    body: '$amount from $client is overdue. Follow up immediately.',
    priority: NotifPriority.urgent,
    payload: {'client': client},
  );

  Future<void> paymentReceived(String client, String amount) => push(
    type: NotifType.paymentReceived, emoji: '💰',
    title: 'Payment Received! 💰',
    body: '$amount received from $client.',
    priority: NotifPriority.high,
  );

  Future<void> jobApplicationFollowup(String company, int daysSince) => push(
    type: NotifType.jobApplicationFollowup, emoji: '📨',
    title: 'Application Follow-Up',
    body: '$daysSince days since you applied to $company. Consider following up!',
  );

  Future<void> dsaMilestone(int problems) => push(
    type: NotifType.dsaStreak, emoji: '🧩',
    title: '$problems Problems Solved!',
    body: 'You\'ve solved $problems DSA problems. Interviews are no match for you.',
  );

  Future<void> journalReminder() => push(
    type: NotifType.journalReminder, emoji: '📔',
    title: 'Daily Dev Journal ✍️',
    body: 'Take 2 minutes to reflect. What did you build today?',
  );

  Future<void> journalStreak(int days) => push(
    type: NotifType.journalReminder, emoji: '📝',
    title: '$days-Day Journal Streak!',
    body: 'Writing daily for $days days. Your dev diary is priceless.',
  );

  // ── Achievements ─────────────────────────────────────────────────
  Future<void> achievementUnlocked(String title, int xp) => push(
    type: NotifType.achievementUnlocked, emoji: '🏆',
    title: 'Achievement Unlocked! 🏆',
    body: '"$title" — +$xp XP added. Keep pushing!',
    priority: NotifPriority.high,
    payload: {'achievement': title, 'xp': xp},
  );

  // ✅ هنا كانت المشكلة — الميثود دي كانت موجودة في achievements_screen.dart
  // بيتكالها لكن مش موجودة في الـ controller → compile error
  Future<void> achievementLocked(String title, int xp) => push(
    type: NotifType.achievementLocked, emoji: '🔒',
    title: 'Achievement Locked',
    body: '"$title" has been locked. Meet the requirements again to unlock it.',
    priority: NotifPriority.low,
    payload: {'achievement': title},
  );

  Future<void> levelUp(String level, String emoji) => push(
    type: NotifType.levelUp, emoji: emoji,
    title: 'Level Up! $emoji',
    body: 'You are now a $level. Your hard work is paying off.',
    priority: NotifPriority.high,
    payload: {'level': level},
  );

  Future<void> xpMilestone(int xp) => push(
    type: NotifType.xpMilestone, emoji: '⚡',
    title: '$xp XP Reached!',
    body: 'You\'ve earned $xp total XP. You\'re climbing fast.',
  );

  // ── System ───────────────────────────────────────────────────────
  Future<void> offlineSynced(int count) => push(
    type: NotifType.offlineDataSynced, emoji: '☁️',
    title: 'Back Online — Synced!',
    body: '$count change${count > 1 ? 's' : ''} synced to cloud.',
    priority: NotifPriority.low,
  );

  Future<void> welcomeBack(int daysMissed) => push(
    type: NotifType.welcomeBack, emoji: '👋',
    title: 'Welcome Back!',
    body: daysMissed > 1
        ? 'You\'ve been away for $daysMissed days. Let\'s pick up where you left off.'
        : 'Good to have you back. What are you building today?',
  );

  Future<void> weeklyDigest({
    required int codingHours,
    required int tasksCompleted,
    required int projectsWorked,
    required int streak,
  }) => push(
    type: NotifType.weeklyDigest, emoji: '📊',
    title: 'Your Weekly Dev Report 📊',
    body: '${codingHours}h coded · $tasksCompleted tasks · $projectsWorked projects · ${streak}d streak',
    priority: NotifPriority.low,
  );

  Future<void> dailyDigest({
    required int tasksToday,
    required int cardsToReview,
    required int streak,
  }) => push(
    type: NotifType.dailyDigest, emoji: '☀️',
    title: 'Good Morning Dev! ☀️',
    body: 'Today: $tasksToday task${tasksToday != 1 ? 's' : ''} · $cardsToReview card${cardsToReview != 1 ? 's' : ''} · ${streak}d streak',
    priority: NotifPriority.low,
  );

  Future<void> newVersion(String version, List<String> features) => push(
    type: NotifType.newAppVersion, emoji: '🚀',
    title: 'Developer OS v$version 🚀',
    body: features.isEmpty ? 'New version available' : features.take(2).join(' · '),
    priority: NotifPriority.low,
    payload: {'version': version},
  );
}

// ═══════════════════════════════════════════════════════════════════
// Scheduler — يشتغل بشكل دوري ويبعت الإشعارات الصح
// ═══════════════════════════════════════════════════════════════════
final notifSchedulerProvider = Provider<NotifScheduler>((ref) {
  final scheduler = NotifScheduler(ref);
  scheduler.start();
  ref.onDispose(scheduler.stop);
  return scheduler;
});

class NotifScheduler {
  final Ref _ref;

  // ✅ FIX: بنحتفظ بـ timestamp آخر check عشان نمنع التكرار
  DateTime? _lastHourlyCheck;
  DateTime? _lastJournalNotif;
  DateTime? _lastFlashcardNotif;

  Timer? _timer;

  NotifScheduler(this._ref);

  void start() {
    // ✅ FIX: بنشيك كل 30 دقيقة بدل كل ساعة عشان ما نفوتش الوقت المضبوط
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => _check());
    // Initial check after 15 seconds من فتح التطبيق
    Future.delayed(const Duration(seconds: 15), _check);
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _check() async {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    // ✅ FIX: منع الـ check لو اتعمل خلال آخر 25 دقيقة
    final now = DateTime.now();
    if (_lastHourlyCheck != null &&
        now.difference(_lastHourlyCheck!).inMinutes < 25) {
      return;
    }
    _lastHourlyCheck = now;

    final ctrl = _ref.read(notifControllerProvider);
    final settings = _ref.read(notifSettingsProvider);

    // Journal reminder — مرة واحدة بس في اليوم الساعة 9 بالليل
    if (settings.journalReminders &&
        now.hour == 21 &&
        (_lastJournalNotif == null || _lastJournalNotif!.day != now.day)) {
      await _checkJournalReminder(uid, ctrl);
    }

    // Flashcard review — مرة في اليوم الساعة 10 الصبح
    if (settings.flashcardReminders &&
        now.hour == 10 &&
        (_lastFlashcardNotif == null || _lastFlashcardNotif!.day != now.day)) {
      await _checkFlashcards(uid, ctrl);
      _lastFlashcardNotif = now;
    }

    // Invoices + Tasks — يتشيك كل check (بس الـ Firestore بيحفظ lastNotif date)
    if (settings.invoiceAlerts) await _checkInvoices(uid, ctrl);
    if (settings.taskReminders) await _checkTasks(uid, ctrl);
  }

  Future<void> _checkJournalReminder(String uid, NotificationController ctrl) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('journal')
          .where('date', isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
          .limit(1).get();
      if (snap.docs.isEmpty) {
        await ctrl.journalReminder();
        _lastJournalNotif = today;
      }
    } catch (_) {}
  }

  Future<void> _checkInvoices(String uid, NotificationController ctrl) async {
    try {
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('fl_invoices')
          .where('status', whereIn: ['sent', 'draft']).get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate'] ?? 0);
        final daysLeft = dueDate.difference(now).inDays;
        final clientName = data['clientName'] ?? 'Client';
        final total = (data['items'] as List?)?.fold(0.0, (s, i) {
          final item = i as Map;
          return s + ((item['quantity'] ?? 1) * (item['unitPrice'] ?? 0)).toDouble();
        }) ?? 0.0;
        final amountStr = '\$${total.toStringAsFixed(0)}';

        if (daysLeft < 0 && data['lastOverdueNotif'] != todayKey) {
          await ctrl.invoiceOverdue(clientName, amountStr);
          await doc.reference.update({'lastOverdueNotif': todayKey});
        } else if (daysLeft <= 3 && daysLeft >= 0 && data['lastDueNotif'] != todayKey) {
          await ctrl.invoiceDue(clientName, amountStr, daysLeft);
          await doc.reference.update({'lastDueNotif': todayKey});
        }
      }
    } catch (_) {}
  }

  Future<void> _checkTasks(String uid, NotificationController ctrl) async {
    try {
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      final projects = await FirebaseFirestore.instance
          .collection('projects')
          .where('uid', isEqualTo: uid)
          .where('status', whereNotIn: ['completed']).get();

      for (final project in projects.docs) {
        final projectName = project.data()['name'] ?? 'Project';
        final tasks = await FirebaseFirestore.instance
            .collection('projects').doc(project.id).collection('tasks')
            .where('completed', isEqualTo: false)
            .where('dueDate', isLessThanOrEqualTo: tomorrow.millisecondsSinceEpoch)
            .get();

        for (final task in tasks.docs) {
          final data = task.data();
          final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate'] ?? 0);
          final taskName = data['title'] ?? 'Task';
          final today = DateTime(now.year, now.month, now.day);
          final daysLate = today.difference(dueDate).inDays;

          if (daysLate > 0 && data['lastOverdueNotif'] != todayKey) {
            await ctrl.taskOverdue(taskName, daysLate, projectName);
            await task.reference.update({'lastOverdueNotif': todayKey});
          } else if (daysLate == 0 && data['lastDueNotif'] != todayKey) {
            await ctrl.taskDue(taskName, projectName);
            await task.reference.update({'lastDueNotif': todayKey});
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _checkFlashcards(String uid, NotificationController ctrl) async {
    try {
      final now = DateTime.now();
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('flashcards')
          .where('nextReview', isLessThanOrEqualTo: now.millisecondsSinceEpoch)
          .get();
      if (snap.docs.length >= 3) {
        await ctrl.flashcardReview(snap.docs.length);
      }
    } catch (_) {}
  }
}