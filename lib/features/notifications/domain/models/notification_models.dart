// lib/features/notifications/domain/models/notification_models.dart

import 'package:flutter/material.dart';

enum NotifType {
  // Project
  taskDue, taskOverdue, projectDeadline, projectMilestone, projectCompleted,
  // Coding
  streakRisk, streakAchieved, codingGoal, pomodoroComplete,
  // Learning
  flashcardReview, learningGoal,
  // Freelance
  invoiceDue, invoiceOverdue, paymentReceived,
  // Interview
  jobApplicationFollowup, dsaStreak,
  // Journal
  journalReminder,
  // Achievements — achievementLocked كانت ناقصة وده اللي كان بيعمل compile error
  achievementUnlocked,
  achievementLocked,
  levelUp,
  xpMilestone,
  // System
  offlineDataSynced, newAppVersion, welcomeBack, weeklyDigest, dailyDigest,
}

enum NotifPriority { urgent, high, normal, low }

class AppNotification {
  final String id;
  final String uid;
  final NotifType type;
  final String title;
  final String body;
  final String emoji;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;
  final bool isDismissed;
  final Map<String, dynamic> payload;
  final NotifPriority priority;

  const AppNotification({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.body,
    required this.emoji,
    required this.createdAt,
    this.scheduledFor,
    this.isRead = false,
    this.isDismissed = false,
    this.payload = const {},
    this.priority = NotifPriority.normal,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}';
  }

  Color get priorityColor {
    switch (priority) {
      case NotifPriority.urgent: return Colors.red;
      case NotifPriority.high:   return Colors.orange;
      case NotifPriority.normal: return Colors.blue;
      case NotifPriority.low:    return Colors.grey;
    }
  }

  String get categoryLabel {
    switch (type) {
      case NotifType.taskDue:
      case NotifType.taskOverdue:
      case NotifType.projectDeadline:
      case NotifType.projectMilestone:
      case NotifType.projectCompleted:
        return 'Projects';
      case NotifType.streakRisk:
      case NotifType.streakAchieved:
      case NotifType.codingGoal:
      case NotifType.pomodoroComplete:
        return 'Coding';
      case NotifType.flashcardReview:
      case NotifType.learningGoal:
        return 'Learning';
      case NotifType.invoiceDue:
      case NotifType.invoiceOverdue:
      case NotifType.paymentReceived:
        return 'Freelance';
      case NotifType.achievementUnlocked:
      case NotifType.achievementLocked:
      case NotifType.levelUp:
      case NotifType.xpMilestone:
        return 'Achievements';
      case NotifType.journalReminder:
        return 'Journal';
      default:
        return 'System';
    }
  }

  factory AppNotification.fromMap(Map<String, dynamic> m, String id) {
    return AppNotification(
      id: id,
      uid: m['uid'] ?? '',
      type: NotifType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => NotifType.welcomeBack,
      ),
      title: m['title'] ?? '',
      body: m['body'] ?? '',
      emoji: m['emoji'] ?? '🔔',
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] ?? 0),
      scheduledFor: m['scheduledFor'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['scheduledFor'])
          : null,
      isRead: m['isRead'] ?? false,
      isDismissed: m['isDismissed'] ?? false,
      payload: Map<String, dynamic>.from(m['payload'] ?? {}),
      priority: NotifPriority.values.firstWhere(
        (p) => p.name == m['priority'],
        orElse: () => NotifPriority.normal,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid, 'type': type.name, 'title': title, 'body': body,
    'emoji': emoji, 'createdAt': createdAt.millisecondsSinceEpoch,
    'scheduledFor': scheduledFor?.millisecondsSinceEpoch,
    'isRead': isRead, 'isDismissed': isDismissed,
    'payload': payload, 'priority': priority.name,
  };

  AppNotification copyWith({bool? isRead, bool? isDismissed}) => AppNotification(
    id: id, uid: uid, type: type, title: title, body: body, emoji: emoji,
    createdAt: createdAt, scheduledFor: scheduledFor,
    isRead: isRead ?? this.isRead,
    isDismissed: isDismissed ?? this.isDismissed,
    payload: payload, priority: priority,
  );
}

class NotifSettings {
  final bool enabled;
  final bool taskReminders;
  final bool flashcardReminders;
  final bool invoiceAlerts;
  final bool achievementAlerts;
  final bool journalReminders;
  final int journalReminderHour;
  final int journalReminderMinute;

  const NotifSettings({
    this.enabled = true,
    this.taskReminders = true,
    this.flashcardReminders = true,
    this.invoiceAlerts = true,
    this.achievementAlerts = true,
    this.journalReminders = true,
    this.journalReminderHour = 21,
    this.journalReminderMinute = 0,
  });

  factory NotifSettings.fromMap(Map<String, dynamic> m) => NotifSettings(
    enabled: m['enabled'] ?? true,
    taskReminders: m['taskReminders'] ?? true,
    flashcardReminders: m['flashcardReminders'] ?? true,
    invoiceAlerts: m['invoiceAlerts'] ?? true,
    achievementAlerts: m['achievementAlerts'] ?? true,
    journalReminders: m['journalReminders'] ?? true,
    journalReminderHour: m['journalReminderHour'] ?? 21,
    journalReminderMinute: m['journalReminderMinute'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'enabled': enabled, 'taskReminders': taskReminders,
    'flashcardReminders': flashcardReminders,
    'invoiceAlerts': invoiceAlerts, 'achievementAlerts': achievementAlerts,
    'journalReminders': journalReminders,
    'journalReminderHour': journalReminderHour,
    'journalReminderMinute': journalReminderMinute,
  };

  NotifSettings copyWith({
    bool? enabled, bool? taskReminders, bool? streakAlerts, bool? pomodoroAlerts,
    bool? flashcardReminders, bool? invoiceAlerts, bool? achievementAlerts,
    bool? journalReminders, bool? weeklyDigest, bool? dailyDigest,
    int? journalReminderHour, int? journalReminderMinute,
    int? dailyDigestHour, int? dailyDigestMinute,
  }) => NotifSettings(
    enabled: enabled ?? this.enabled,
    taskReminders: taskReminders ?? this.taskReminders,
    flashcardReminders: flashcardReminders ?? this.flashcardReminders,
    invoiceAlerts: invoiceAlerts ?? this.invoiceAlerts,
    achievementAlerts: achievementAlerts ?? this.achievementAlerts,
    journalReminders: journalReminders ?? this.journalReminders,
    journalReminderHour: journalReminderHour ?? this.journalReminderHour,
    journalReminderMinute: journalReminderMinute ?? this.journalReminderMinute,
  );
}