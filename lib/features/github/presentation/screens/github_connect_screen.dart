import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';

class GitHubConnectScreen extends ConsumerStatefulWidget {
  const GitHubConnectScreen({super.key});

  @override
  ConsumerState<GitHubConnectScreen> createState() =>
      _GitHubConnectScreenState();
}

class _GitHubConnectScreenState extends ConsumerState<GitHubConnectScreen> {
  final _tokenCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_tokenCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ref
        .read(githubTokenProvider.notifier)
        .saveToken(_tokenCtrl.text.trim());

    setState(() => _loading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Invalid token. Please check and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios,
                    color: isDark ? AppTheme.white : AppTheme.black, size: 20),
              ),
              const SizedBox(height: 32),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? AppTheme.white : AppTheme.black)
                        .withOpacity(0.1),
                  ),
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.github,
                        size: 40,
                        color: isDark ? AppTheme.white : AppTheme.black),
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Center(
                child: Text('Connect GitHub',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.white : AppTheme.black,
                    )),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                    'Link your GitHub account to auto-create repos',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                    textAlign: TextAlign.center),
              ),

              const SizedBox(height: 32),

              // Steps
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to get your token:',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        )),
                    const SizedBox(height: 12),
                    ...[
                      '1. Go to github.com → Settings',
                      '2. Developer settings → Personal access tokens',
                      '3. Tokens (classic) → Generate new token',
                      '4. Select scopes: repo, user, read:org',
                      '5. Copy the token and paste below',
                    ].map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 5, right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppTheme.silver : AppTheme.gray,
                                ),
                              ),
                              Expanded(
                                child: Text(step,
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 12,
                                      color: isDark ? AppTheme.lightGray : AppTheme.gray,
                                    )),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => launchUrl(
                          Uri.parse(
                              'https://github.com/settings/tokens/new'),
                          mode: LaunchMode.externalApplication),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.07),
                          border: Border.all(
                              color: (isDark ? AppTheme.white : AppTheme.black)
                                  .withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new,
                                size: 14,
                                color: isDark ? AppTheme.silver : AppTheme.gray),
                            const SizedBox(width: 6),
                            Text('Open GitHub Token Page',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12,
                                  color: isDark ? AppTheme.silver : AppTheme.gray,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Token Input
              GlassTextField(
                controller: _tokenCtrl,
                hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                labelText: 'Personal Access Token',
                obscureText: _obscure,
                prefixIcon: Container(width: 20, alignment: Alignment.center, child: FaIcon(FontAwesomeIcons.key, size: 16, color: isDark ? AppTheme.gray : AppTheme.lightGray),),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                color: Colors.red))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              GlassButton(
                label: 'Connect GitHub',
                onPressed: _connect,
                isLoading: _loading,
                icon: FaIcon(FontAwesomeIcons.github,
                    size: 16,
                    color: isDark ? AppTheme.black : AppTheme.white),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}