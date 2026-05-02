import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';
import 'package:developer_os/features/github/presentation/screens/github_connect_screen.dart';

class GitHubStatsWidget extends ConsumerWidget {
  const GitHubStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final token = ref.watch(githubTokenProvider);

    if (token == null) {
      return _NotConnectedCard(isDark: isDark);
    }

    final statsAsync = ref.watch(githubStatsProvider);

    return statsAsync.when(
      loading: () => GlassCard(
        child: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              color: isDark ? AppTheme.white : AppTheme.black,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (e, _) => GlassCard(
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
              child: Text('GitHub error. Check token.',
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: isDark ? AppTheme.white : AppTheme.black))),
          GestureDetector(
            onTap: () => ref.read(githubTokenProvider.notifier).clearToken(),
            child: Text('Disconnect',
                style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: Colors.red)),
          ),
        ]),
      ),
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.github,
                      size: 16,
                      color: isDark ? AppTheme.white : AppTheme.black),
                  const SizedBox(width: 8),
                  Text('GitHub',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      )),
                  const Spacer(),
                  // Avatar
                  if (stats.avatarUrl != null)
                    CircleAvatar(
                      radius: 14,
                      backgroundImage:
                          CachedNetworkImageProvider(stats.avatarUrl!),
                    ),
                  const SizedBox(width: 8),
                  Text('@${stats.username}',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      )),
                ],
              ),
              const SizedBox(height: 14),

              // Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                      value: '${stats.totalRepos}',
                      label: 'Repos',
                      icon: FontAwesomeIcons.codeBranch,
                      isDark: isDark),
                  _StatItem(
                      value: '${stats.totalStars}',
                      label: 'Stars',
                      icon: FontAwesomeIcons.star,
                      isDark: isDark),
                  _StatItem(
                      value: '${stats.followers}',
                      label: 'Followers',
                      icon: FontAwesomeIcons.users,
                      isDark: isDark),
                  _StatItem(
                      value: '${stats.totalForks}',
                      label: 'Forks',
                      icon: FontAwesomeIcons.codeCommit,
                      isDark: isDark),
                ],
              ),

              if (stats.topLanguage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: (isDark ? AppTheme.white : AppTheme.black)
                        .withOpacity(0.07),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code,
                          size: 12,
                          color: isDark ? AppTheme.silver : AppTheme.gray),
                      const SizedBox(width: 6),
                      Text('Top: ${stats.topLanguage}',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: isDark ? AppTheme.silver : AppTheme.gray,
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }
}

class _NotConnectedCard extends StatelessWidget {
  final bool isDark;
  const _NotConnectedCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Row(children: [
            FaIcon(FontAwesomeIcons.github,
                size: 20, color: isDark ? AppTheme.white : AppTheme.black),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GitHub Not Connected',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        )),
                    Text('Connect to auto-create repos',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                        )),
                  ]),
            ),
            GlassButton(
              label: 'Connect',
              width: 100,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GitHubConnectScreen()),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final bool isDark;

  const _StatItem(
      {required this.value,
      required this.label,
      required this.icon,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon,
            size: 14, color: isDark ? AppTheme.silver : AppTheme.gray),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.white : AppTheme.black,
            )),
        Text(label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              color: isDark ? AppTheme.gray : AppTheme.lightGray,
              letterSpacing: 0.5,
            )),
      ],
    );
  }
}