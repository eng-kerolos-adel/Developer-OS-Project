import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/features/offline/providers/connectivity_provider.dart';
 
/// Drop this widget at the TOP of your Scaffold body
/// to show an animated offline banner when no internet
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectivityProvider);
    if (conn.isOnline) return const SizedBox.shrink();
    return _OfflineBannerContent(conn: conn);
  }
}
 
class _OfflineBannerContent extends ConsumerWidget {
  final ConnectivityState conn;
  const _OfflineBannerContent({required this.conn});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    return GestureDetector(
      onTap: () => ref.read(connectivityProvider.notifier).forceCheck(),
      child: Container(
        width: double.infinity,
        // بنخلي الـ Padding من فوق = الـ Notch + الـ 10 الأساسيين بتوعك
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade800,
              Colors.red.shade700,
            ],
          ),
        ),
        child: Row(
          children: [
            // Pulsing wifi-off icon
            _PulsingIcon(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You\'re offline',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    conn.pendingSyncCount > 0
                        ? '${conn.pendingSyncCount} change${conn.pendingSyncCount > 1 ? 's' : ''} will sync when back online'
                        : 'Changes saved locally — will sync when connected',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Retry button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 300.ms);
  }
}
 
class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}
 
class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl),
      child: const Icon(Icons.wifi_off, color: Colors.white, size: 18),
    );
  }
}
 
/// Small status dot — use in app bar or nav bar
class ConnectivityDot extends ConsumerWidget {
  const ConnectivityDot({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectivityProvider);
    if (conn.isOnline) return const SizedBox.shrink();
 
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange,
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 6),
        ],
      ),
    ).animate().scale(duration: 600.ms).then().shake(hz: 1);
  }
}