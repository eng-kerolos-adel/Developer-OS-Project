import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/route_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/animated_background.dart';
import 'package:developer_os/features/home/presentation/screens/home_dashboard.dart';
import 'package:developer_os/features/notifications/providers/notification_provider.dart';
import 'package:developer_os/features/offline/providers/connectivity_provider.dart';
import 'package:developer_os/features/updates/update_system.dart';
import 'package:developer_os/shared/widgets/offline_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Projects'),
    // _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics'),
    _NavItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: 'Journal'),
    _NavItem(icon: Icons.code_outlined, activeIcon: Icons.code, label: 'Snippets'),
    _NavItem(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Interview'),
    // _NavItem(icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'Pomodoro'),
    _NavItem(icon: Icons.style_outlined, activeIcon: Icons.style, label: 'Cards'),
    _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Learning'),
    _NavItem(icon: Icons.attach_money_outlined, activeIcon: Icons.attach_money, label: 'Freelance'),
    // _NavItem(icon: Icons.build_outlined, activeIcon: Icons.build, label: 'Tools'),
    _NavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Awards'),
    _NavItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'Skills'),
    _NavItem(icon: Icons.link_outlined, activeIcon: Icons.link, label: 'Links'),
    // _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Portfolio'),
    _NavItem(icon: Icons.info_outlined, activeIcon: Icons.info, label: 'Readme'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifs'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
    // _NavItem(icon: Icons.info_outlined, activeIcon: Icons.info, label: 'Info'),
  ];

  static const _routes = [
    RouteConstants.home, 
    RouteConstants.profile, 
    RouteConstants.projects, 
    // RouteConstants.analytics,
    RouteConstants.journal,
    RouteConstants.snippets, 
    RouteConstants.interview, 
    // RouteConstants.pomodoro, 
    RouteConstants.cards, 
    RouteConstants.learning,
    RouteConstants.freelance, 
    // RouteConstants.tools,
    RouteConstants.awards, 
    RouteConstants.skills, 
    RouteConstants.links, 
    RouteConstants.readmeGenerator, 
    RouteConstants.notifs, 
    // RouteConstants.portfolio, 
    RouteConstants.settings, 
    // RouteConstants.info,
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = ref.watch(unreadCountProvider);
    final isOffline = ref.watch(connectivityProvider).isOffline;

    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            // ── Offline Banner (top of screen) ──────────────
            const OfflineBanner(),

            // ── Update Banner (below offline) ───────────────
            const UpdateBanner(),

            // ── Main Screen Content ─────────────────────────
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        selectedIndex: _selectedIndex,
        items: _navItems,
        unreadCount: unreadCount,
        isOffline: isOffline,
        onTap: _onNavTap,
        isDark: isDark,
      ),
    );
  }
}


class _GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final int unreadCount;
  final bool isOffline;
  final void Function(int) onTap;
  final bool isDark;

  const _GlassNavBar({
    required this.selectedIndex,
    required this.items,
    required this.unreadCount,
    required this.isOffline,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.black : AppTheme.white).withOpacity(0.88),
            border: Border(
              top: BorderSide(
                color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isSelected = i == selectedIndex;

                  // Special: notifications tab with badge
                  final isNotifTab = i == 15;
                  // Special: offline dot on first tab
                  final isHomeTab = i == 0;

                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isSelected ? 80 : 65,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isSelected
                            ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  key: ValueKey(isSelected),
                                  size: 25,
                                  color: isSelected
                                      ? (isDark ? AppTheme.white : AppTheme.black)
                                      : (isDark ? AppTheme.gray : AppTheme.lightGray),
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  letterSpacing: 0.2,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                  color: isSelected
                                      ? (isDark ? AppTheme.white : AppTheme.black)
                                      : (isDark ? AppTheme.gray : AppTheme.lightGray),
                                ),
                                child: Text(item.label.toUpperCase()),
                              ),
                            ],
                          ),

                          // Notification badge
                          if (isNotifTab && unreadCount > 0)
                            Positioned(
                              right: 10, top: 6,
                              child: Container(
                                width: unreadCount > 9 ? 18 : 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: Colors.red,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                            ),

                          // Offline dot on home tab
                          if (isHomeTab && isOffline)
                            Positioned(
                              right: 10, top: 6,
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange,
                                  border: Border.all(
                                    color: isDark ? AppTheme.darkest : AppTheme.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const HomeDashboardContent();
}