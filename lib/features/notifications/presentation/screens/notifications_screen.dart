// lib/features/notifications/presentation/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/notifications/domain/models/notification_models.dart';
import 'package:developer_os/features/notifications/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filterCategory = 'All';

  static const _categories = [
    'All',
    'Projects',
    'Coding',
    'Learning',
    'Freelance',
    'Achievements',
    'Journal',
    'System',
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
    final notifsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('// activity feed',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Row(children: [
                    Text('Notifications',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                  ]),
                ]),

                // Actions
                Row(children: [
                  // Mark all read
                  if (unread > 0)
                    GestureDetector(
                      onTap: () =>
                          ref.read(notifControllerProvider).markAllRead(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blue.withOpacity(0.1),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Text('Mark all read',
                            style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Clear all
                  GestureDetector(
                    onTap: () => _confirmClearAll(context, isDark),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (isDark ? AppTheme.white : AppTheme.black)
                            .withOpacity(0.07),
                      ),
                      child: Icon(Icons.delete_sweep_outlined,
                          size: 18,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray),
                    ),
                  ),
                ]),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 16),

          // ── Tabs ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabCtrl,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: isDark ? AppTheme.black : AppTheme.white,
                unselectedLabelColor:
                    isDark ? AppTheme.gray : AppTheme.lightGray,
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
                  Tab(text: 'NOTIFICATIONS'),
                  Tab(text: 'SETTINGS'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Category Filter ───────────────────────────────────
          AnimatedBuilder(
            animation: _tabCtrl.animation!,
            builder: (context, _) {
              final idx = (_tabCtrl.animation!.value).round();
              if (idx != 0) return const SizedBox.shrink();
              return SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _categories.map((cat) {
                    final isSelected = _filterCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _filterCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isSelected
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black)
                                  .withOpacity(0.07),
                          border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? AppTheme.white : AppTheme.black)
                                      .withOpacity(0.1)),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? (isDark ? AppTheme.black : AppTheme.white)
                                    : (isDark
                                        ? AppTheme.silver
                                        : AppTheme.gray))),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Content ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Notifications list
                notifsAsync.when(
                  loading: () => Center(
                      child: CircularProgressIndicator(
                          color: isDark ? AppTheme.white : AppTheme.black,
                          strokeWidth: 2)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (notifs) {
                    final filtered = _filterCategory == 'All'
                        ? notifs
                        : notifs
                            .where((n) => n.categoryLabel == _filterCategory)
                            .toList();

                    if (filtered.isEmpty) {
                      return _EmptyNotifs(
                          isDark: isDark, category: _filterCategory);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        return _NotifCard(
                          notif: filtered[i],
                          isDark: isDark,
                          index: i,
                          onRead: () => ref
                              .read(notifControllerProvider)
                              .markRead(filtered[i].id),
                          onDismiss: () => ref
                              .read(notifControllerProvider)
                              .dismiss(filtered[i].id),
                        );
                      },
                    );
                  },
                ),

                // Settings tab
                _NotifSettingsTab(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
        title: Text('Clear All Notifications',
            style: TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.white : AppTheme.black)),
        content: Text('This will dismiss all notifications.',
            style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                color: isDark ? AppTheme.silver : AppTheme.gray)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel',
                  style: TextStyle(
                      color: isDark ? AppTheme.gray : AppTheme.lightGray))),
          TextButton(
            onPressed: () {
              ref.read(notifControllerProvider).dismissAll();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Notification Card ───────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final bool isDark;
  final int index;
  final VoidCallback onRead, onDismiss;

  const _NotifCard({
    required this.notif,
    required this.isDark,
    required this.index,
    required this.onRead,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.red.withOpacity(0.1),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
      ),
      child: GestureDetector(
        onTap: isUnread ? onRead : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isUnread
                ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06)
                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.03),
            border: Border.all(
              color: isUnread
                  ? notif.priorityColor.withOpacity(0.3)
                  : (isDark ? AppTheme.white : AppTheme.black)
                      .withOpacity(0.08),
              width: isUnread ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji + priority dot
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: (isDark ? AppTheme.white : AppTheme.black)
                          .withOpacity(0.07),
                    ),
                    child: Center(
                      child: Text(notif.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: notif.priorityColor,
                          border: Border.all(
                              color: isDark ? AppTheme.darkest : AppTheme.white,
                              width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isDark ? AppTheme.white : AppTheme.black,
                              )),
                        ),
                        Text(notif.timeAgo,
                            style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 9,
                                color: isDark
                                    ? AppTheme.gray
                                    : AppTheme.lightGray)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif.body,
                        style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? AppTheme.silver : AppTheme.gray)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _tag(notif.categoryLabel, isDark),
                      const SizedBox(width: 6),
                      if (notif.priority == NotifPriority.urgent)
                        _tag('URGENT', isDark, color: Colors.red),
                      if (notif.priority == NotifPriority.high)
                        _tag('HIGH', isDark, color: Colors.orange),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40));
  }

  Widget _tag(String label, bool isDark, {Color? color}) {
    final c = color ?? (isDark ? AppTheme.white : AppTheme.black);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: c.withOpacity(0.1),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.5)),
    );
  }
}

// ── Settings Tab ───────────────────────────────────────────────────
class _NotifSettingsTab extends ConsumerWidget {
  final bool isDark;
  const _NotifSettingsTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notifSettingsProvider);
    final ctrl = ref.read(notifSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      physics: const BouncingScrollPhysics(),
      children: [
        // Master toggle
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('🔔', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('All Notifications',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                  Text('Master switch for all alerts',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                ])),
            Switch(
              value: settings.enabled,
              activeColor: isDark ? AppTheme.white : AppTheme.black,
              onChanged: (v) => ctrl.update(settings.copyWith(enabled: v)),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        if (settings.enabled) ...[
          // Section header
          _sectionHeader('Reminders & Alerts', isDark),
          const SizedBox(height: 10),

          // Toggle list
          GlassCard(
            child: Column(children: [
              _toggle(
                  '📋',
                  'Task Reminders',
                  'Due dates, overdue tasks',
                  settings.taskReminders,
                  isDark,
                  (v) => ctrl.update(settings.copyWith(taskReminders: v))),
              _divider(isDark),
              _toggle(
                  '🃏',
                  'Flashcard Reviews',
                  'Spaced-repetition reminders',
                  settings.flashcardReminders,
                  isDark,
                  (v) => ctrl.update(settings.copyWith(flashcardReminders: v))),
              _divider(isDark),
              _toggle(
                  '💸',
                  'Invoice Alerts',
                  'Due dates and overdue invoices',
                  settings.invoiceAlerts,
                  isDark,
                  (v) => ctrl.update(settings.copyWith(invoiceAlerts: v))),
              _divider(isDark),
              _toggle(
                  '🏆',
                  'Achievement Alerts',
                  'Badges, levels, and XP milestones',
                  settings.achievementAlerts,
                  isDark,
                  (v) => ctrl.update(settings.copyWith(achievementAlerts: v))),
              _divider(isDark),
              _toggle(
                  '📔',
                  'Journal Reminders',
                  'Daily writing reminder',
                  settings.journalReminders,
                  isDark,
                  (v) => ctrl.update(settings.copyWith(journalReminders: v))),
            ]),
          ),

          const SizedBox(height: 16),

          GlassCard(
            onTap: () async {
              await ref
                  .read(notifControllerProvider)
                  .achievementUnlocked('Test Achievement', 100);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('✅ Test notification sent!',
                      style:
                          TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12)),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            child: Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.purple.withOpacity(0.1)),
                  child: const Center(
                      child: Text('🧪', style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Send Test Notification',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                    Text('Verify your settings are working',
                        style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color:
                                isDark ? AppTheme.gray : AppTheme.lightGray)),
                  ])),
              Icon(Icons.arrow_forward_ios,
                  size: 13, color: isDark ? AppTheme.gray : AppTheme.lightGray),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Text(title,
      style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: isDark ? AppTheme.gray : AppTheme.lightGray));

  Widget _divider(bool isDark) => Divider(
      height: 1,
      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07));

  Widget _toggle(String emoji, String title, String subtitle, bool value,
      bool isDark, ValueChanged<bool> onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.white : AppTheme.black)),
          Text(subtitle,
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ])),
        Switch(
          value: value,
          activeColor: isDark ? AppTheme.white : AppTheme.black,
          onChanged: onChange,
        ),
      ]),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────
class _EmptyNotifs extends StatelessWidget {
  final bool isDark;
  final String category;

  const _EmptyNotifs({required this.isDark, required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
              category == 'All'
                  ? 'No notifications'
                  : 'No $category notifications',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 8),
          Text('// all caught up!',
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ],
      ).animate().fadeIn().scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutBack),
    );
  }
}

// ── In-App Notification Toast (overlay) ────────────────────────────
class NotifToast extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onDismiss;

  const NotifToast({super.key, required this.notif, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (isDark ? AppTheme.dark : AppTheme.white).withOpacity(0.95),
          border: Border.all(
              color: notif.priorityColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(children: [
          Text(notif.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(notif.title,
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black)),
                Text(notif.body,
                    style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: isDark ? AppTheme.silver : AppTheme.gray),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ])),
          const SizedBox(width: 8),
          Icon(Icons.close,
              size: 16, color: isDark ? AppTheme.gray : AppTheme.lightGray),
        ]),
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 350.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 300.ms);
  }
}

/// Global overlay for showing toast notifications
class NotifToastManager {
  static OverlayEntry? _current;

  static void show(BuildContext context, AppNotification notif) {
    _current?.remove();

    _current = OverlayEntry(builder: (ctx) {
      return Positioned(
        top: MediaQuery.of(ctx).padding.top + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: NotifToast(
            notif: notif,
            onDismiss: () {
              _current?.remove();
              _current = null;
            },
          ),
        ),
      );
    });

    Overlay.of(context).insert(_current!);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _current?.remove();
      _current = null;
    });
  }
}
