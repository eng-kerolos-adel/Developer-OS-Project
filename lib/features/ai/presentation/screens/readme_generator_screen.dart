// lib/features/ai/presentation/screens/readme_generator_screen.dart
// ═══════════════════════════════════════════════════════════════════
// AI README Generator — Generates professional README.md for any project
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/ai/services/ai_provider.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:go_router/go_router.dart';

// ═══════════════════════════════════════════════════════════════════
// README Style Options
// ═══════════════════════════════════════════════════════════════════
enum ReadmeStyle {
  professional,
  minimal,
  detailed,
  startup,
}

extension ReadmeStyleX on ReadmeStyle {
  String get label => switch (this) {
    ReadmeStyle.professional => 'Professional',
    ReadmeStyle.minimal => 'Minimal',
    ReadmeStyle.detailed => 'Detailed',
    ReadmeStyle.startup => 'Startup',
  };
  String get emoji => switch (this) {
    ReadmeStyle.professional => '👔',
    ReadmeStyle.minimal => '⚡',
    ReadmeStyle.detailed => '📚',
    ReadmeStyle.startup => '🚀',
  };
  String get desc => switch (this) {
    ReadmeStyle.professional => 'Clean, formal for open-source',
    ReadmeStyle.minimal => 'Short, essential info only',
    ReadmeStyle.detailed => 'Comprehensive with all sections',
    ReadmeStyle.startup => 'Marketing-focused, engaging',
  };
}

// ═══════════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════════
class ReadmeGeneratorState {
  final bool isGenerating;
  final String? readme;
  final String? error;
  final bool showPreview;
  final ReadmeStyle style;
  final Project? selectedProject;
  final Map<String, bool> sections;

  const ReadmeGeneratorState({
    this.isGenerating = false,
    this.readme,
    this.error,
    this.showPreview = false,
    this.style = ReadmeStyle.professional,
    this.selectedProject,
    this.sections = const {
      'badges': true,
      'description': true,
      'features': true,
      'installation': true,
      'usage': true,
      'api': false,
      'contributing': true,
      'license': true,
      'contact': true,
    },
  });

  ReadmeGeneratorState copyWith({
    bool? isGenerating, String? readme, String? error,
    bool? showPreview, ReadmeStyle? style, Project? selectedProject,
    Map<String, bool>? sections,
  }) => ReadmeGeneratorState(
    isGenerating: isGenerating ?? this.isGenerating,
    readme: readme ?? this.readme,
    error: error ?? this.error,
    showPreview: showPreview ?? this.showPreview,
    style: style ?? this.style,
    selectedProject: selectedProject ?? this.selectedProject,
    sections: sections ?? this.sections,
  );
}

final readmeGeneratorProvider =
    StateNotifierProvider<ReadmeGeneratorNotifier, ReadmeGeneratorState>((ref) {
  return ReadmeGeneratorNotifier(ref);
});

class ReadmeGeneratorNotifier extends StateNotifier<ReadmeGeneratorState> {
  final Ref _ref;
  ReadmeGeneratorNotifier(this._ref) : super(const ReadmeGeneratorState());

  void selectProject(Project project) {
    state = state.copyWith(selectedProject: project, readme: null, error: null);
  }

  void setStyle(ReadmeStyle style) => state = state.copyWith(style: style);

  void toggleSection(String key) {
    final updated = Map<String, bool>.from(state.sections);
    updated[key] = !(updated[key] ?? true);
    state = state.copyWith(sections: updated);
  }

  void togglePreview() => state = state.copyWith(showPreview: !state.showPreview);

  Future<void> generate() async {
    final project = state.selectedProject;
    if (project == null) return;

    final service = _ref.read(aiServiceProvider);
    if (service == null) {
      state = state.copyWith(
          error: 'AI not configured. Add your Gemini API key in Settings.');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null, readme: null);

    try {
      final sections = state.sections.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .join(', ');

      final stylePrompt = switch (state.style) {
        ReadmeStyle.professional =>
          'Write in a professional, clean tone. Use standard markdown formatting.',
        ReadmeStyle.minimal =>
          'Keep it very concise. Only essential sections. No fluff.',
        ReadmeStyle.detailed =>
          'Be comprehensive. Include all requested sections with detailed explanations, badges, and examples.',
        ReadmeStyle.startup =>
          'Write in an engaging, energetic startup tone. Use emojis, bold statements, and exciting language.',
      };

      final prompt = '''
Generate a professional README.md file for this project:

PROJECT INFO:
- Name: ${project.name}
- Description: ${project.description ?? 'No description provided'}
- Status: ${project.status}
- Tech Stack: ${project.techStack.join(', ')}
- GitHub: ${project.githubUrl ?? 'Not linked'}

STYLE: ${state.style.label}
$stylePrompt

SECTIONS TO INCLUDE: $sections

REQUIREMENTS:
- Use proper Markdown formatting
- Include actual, practical content (not placeholder text)
- Make installation steps realistic for the tech stack used
- Add relevant badges if "badges" section is enabled (shields.io format)
- For Flutter projects: include pubspec.yaml snippet
- For web projects: include npm/yarn commands
- For Python projects: include pip commands
- Make the project sound professional and well-maintained
- Include emojis strategically (not excessively)
- The README should be immediately usable — no [placeholder] text

Output ONLY the README.md content. No preamble, no explanation.
Start directly with # ${project.name}
''';

      final result = await service.generateReadme(prompt);

      if (mounted && result.isNotEmpty) {
        state = state.copyWith(isGenerating: false, readme: result.trim());
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isGenerating: false,
          error: 'Generation failed: ${e.toString()}',
        );
      }
    }
  }

  void clear() => state = const ReadmeGeneratorState();
}

// ═══════════════════════════════════════════════════════════════════
// Screen
// ═══════════════════════════════════════════════════════════════════
class ReadmeGeneratorScreen extends ConsumerWidget {
  const ReadmeGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state  = ref.watch(readmeGeneratorProvider);
    final notifier = ref.read(readmeGeneratorProvider.notifier);
    final projectsAsync = ref.watch(projectsProvider);

    if (state.readme != null && state.showPreview) {
      return _ReadmePreviewScreen(readme: state.readme!, isDark: isDark, onClose: () => notifier.togglePreview());
    }

    return SafeArea(
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('// ai powered', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
              Text('README Generator', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.white : AppTheme.black)),
            ]),
            if (state.readme != null)
              GestureDetector(
                onTap: notifier.clear,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                      color: Colors.red.withOpacity(0.1)),
                  child: const Text('Reset', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                      color: Colors.red))),
              ),
          ]).animate().fadeIn(),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: state.readme != null
              ? _ReadmeResultView(readme: state.readme!, isDark: isDark, state: state)
              : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // Step 1: Select Project
              _Step(number: '01', title: 'Select Project', isDark: isDark),
              const SizedBox(height: 10),

              projectsAsync.when(
                loading: () => Center(child: CircularProgressIndicator(
                    color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
                error: (e, _) => Text('Error: $e'),
                data: (projects) {
                  if (projects.isEmpty) {
                    return GlassCard(child: Column(children: [
                      const Text('📁', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text('No projects yet. Create a project first.',
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    ]));
                  }

                  return Column(children: projects.map((p) {
                    final isSelected = state.selectedProject?.id == p.id;
                    return GestureDetector(
                      onTap: () => notifier.selectProject(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected
                              ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.04),
                          border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.4)
                                  : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                              width: isSelected ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              size: 20, color: isSelected
                                  ? (isDark ? AppTheme.white : AppTheme.black)
                                  : (isDark ? AppTheme.gray : AppTheme.lightGray)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name, style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.white : AppTheme.black)),
                            if (p.techStack.isNotEmpty)
                              Text(p.techStack.take(4).join(' · '),
                                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                                      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                          ])),
                          if (p.githubUrl != null)
                            const Icon(Icons.hub_outlined, size: 14, color: Colors.green),
                        ]),
                      ),
                    );
                  }).toList());
                },
              ),

              const SizedBox(height: 20),

              // Step 2: Style
              _Step(number: '02', title: 'README Style', isDark: isDark),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
                children: ReadmeStyle.values.map((style) {
                  final isSelected = state.style == style;
                  return GestureDetector(
                    onTap: () => notifier.setStyle(style),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isSelected
                            ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)
                            : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.04),
                        border: Border.all(color: isSelected
                            ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.5)
                            : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                            width: isSelected ? 1.5 : 1),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, children: [
                        Row(children: [
                          Text(style.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(style.label, style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black)),
                        ]),
                        const SizedBox(height: 4),
                        Text(style.desc, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                            height: 1.4, color: isDark ? AppTheme.gray : AppTheme.lightGray),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // Step 3: Sections
              _Step(number: '03', title: 'Sections to Include', isDark: isDark),
              const SizedBox(height: 10),

              GlassCard(child: Wrap(
                spacing: 8, runSpacing: 8,
                children: state.sections.entries.map((e) {
                  final isOn = e.value;
                  final labels = {
                    'badges': '🏷️ Badges', 'description': '📝 Description',
                    'features': '✨ Features', 'installation': '⚙️ Installation',
                    'usage': '📖 Usage', 'api': '🔌 API Docs',
                    'contributing': '🤝 Contributing', 'license': '📄 License',
                    'contact': '💬 Contact',
                  };
                  return GestureDetector(
                    onTap: () => notifier.toggleSection(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isOn
                            ? (isDark ? AppTheme.white : AppTheme.black)
                            : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        border: Border.all(color: isOn
                            ? Colors.transparent
                            : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                      ),
                      child: Text(labels[e.key] ?? e.key,
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOn
                                  ? (isDark ? AppTheme.black : AppTheme.white)
                                  : (isDark ? AppTheme.silver : AppTheme.gray))),
                    ),
                  );
                }).toList(),
              )).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Error
              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.error!, style: const TextStyle(
                        fontFamily: 'JetBrainsMono', fontSize: 12, color: Colors.red))),
                  ]),
                ),

              // Generate Button
              GestureDetector(
                onTap: state.selectedProject == null || state.isGenerating
                    ? null
                    : notifier.generate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: state.selectedProject != null && !state.isGenerating
                        ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)])
                        : null,
                    color: state.selectedProject == null || state.isGenerating
                        ? (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)
                        : null,
                    boxShadow: state.selectedProject != null && !state.isGenerating ? [
                      BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4)),
                    ] : null,
                  ),
                  child: state.isGenerating
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    const SizedBox(width: 12),
                    const Text('Generating README...', style: TextStyle(fontFamily: 'Syne',
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ])
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('✨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('Generate README',
                        style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: state.selectedProject != null ? Colors.white
                                : (isDark ? AppTheme.gray : AppTheme.lightGray))),
                  ]),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Step indicator ───────────────────────────────────────────────
class _Step extends StatelessWidget {
  final String number, title;
  final bool isDark;
  const _Step({required this.number, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle,
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
        child: Center(child: Text(number, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
            fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)))),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.white : AppTheme.black)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
// README Result View
// ═══════════════════════════════════════════════════════════════════
class _ReadmeResultView extends ConsumerWidget {
  final String readme;
  final bool isDark;
  final ReadmeGeneratorState state;
  const _ReadmeResultView({required this.readme, required this.isDark, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(readmeGeneratorProvider.notifier);

    return Column(children: [
      // Action bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          // Copy
          Expanded(child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: readme));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('📋 README copied!', style: TextStyle(fontFamily: 'JetBrainsMono')),
                duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                  border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.copy, size: 16, color: isDark ? AppTheme.white : AppTheme.black),
                const SizedBox(width: 6),
                Text('Copy', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                    fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
              ])),
          )),
          const SizedBox(width: 8),
          // Share
          Expanded(child: GestureDetector(
            onTap: () => Share.share(readme, subject: 'README.md'),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                  border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.share, size: 16, color: isDark ? AppTheme.white : AppTheme.black),
                const SizedBox(width: 6),
                Text('Share', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                    fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
              ])),
          )),
          const SizedBox(width: 8),
          // Preview
          Expanded(child: GestureDetector(
            onTap: notifier.togglePreview,
            child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)])),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                const Text('Preview', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
          )),
        ]),
      ),

      const SizedBox(height: 12),

      // Stats bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Stat('Lines', '${readme.split('\n').length}', isDark),
            _Stat('Words', '${readme.split(RegExp(r'\s+')).length}', isDark),
            _Stat('Chars', '${readme.length}', isDark),
            _Stat('Style', state.style.emoji, isDark),
          ]),
        ),
      ),

      const SizedBox(height: 12),

      // Raw markdown view
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
              color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFFF6F8FA),
              border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1))),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SelectableText(readme, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                height: 1.6, color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Regenerate
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: ref.read(readmeGeneratorProvider.notifier).generate,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🔄', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text('Regenerate', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                  fontWeight: FontWeight.w700, color: isDark ? AppTheme.silver : AppTheme.gray)),
            ])),
        ),
      ),

      const SizedBox(height: 16),
    ]);
  }
}

Widget _Stat(String label, String value, bool isDark) => Column(children: [
  Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800,
      color: isDark ? AppTheme.white : AppTheme.black)),
  Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
]);

// ═══════════════════════════════════════════════════════════════════
// Preview Screen — rendered markdown view
// ═══════════════════════════════════════════════════════════════════
class _ReadmePreviewScreen extends StatelessWidget {
  final String readme;
  final bool isDark;
  final VoidCallback onClose;

  const _ReadmePreviewScreen({required this.readme, required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final lines = readme.split('\n');
    final theme = Theme.of(context);

    return Scaffold(
      // بيسحب لون الخلفية من الـ scaffoldBackgroundColor بتاعك
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // خليته شفاف زي ثيم الـ AppBar عندك
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios, 
            color: theme.colorScheme.onBackground,
          ),
          onPressed: onClose,
        ),
        title: Row(
          children: [
            Icon(
              Icons.description_outlined, 
              size: 18,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'README.md', 
              style: theme.textTheme.titleSmall, // بيستخدم JetBrainsMono من الثيم
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.copy, 
              size: 20, 
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: readme));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Copied!', 
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary),
                ),
                duration: const Duration(seconds: 1), 
                behavior: SnackBarBehavior.floating,
                backgroundColor: theme.colorScheme.primary, // بيستخدم الأسود أو الأبيض الأساسي
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) => _renderLine(context, line)).toList(),
        ),
      ),
    );
  }

  Widget _renderLine(BuildContext context, String line) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;
    final subColor = theme.colorScheme.onBackground.withOpacity(0.7);

    // H1 -> بيستخدم Syne من الـ headlineMedium
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          line.substring(2), 
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }

    // H2 -> بيستخدم Syne مع الـ Divider بتاع الثيم
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(
              line.substring(3), 
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Divider(color: theme.dividerColor.withOpacity(0.3)),
          ],
        ),
      );
    }

    // H3 -> بيستخدم Syne
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          line.substring(4), 
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    // الـ Code Blocks -> سحبت الـ glass colors عشان تبقى لايقة مع الثيم
    if (line.startsWith('```')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000), // glassWhite أو glassDark
          border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        ),
        child: const SizedBox.shrink(),
      );
    }

    // الـ Lists
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 4, 
                height: 4, 
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: subColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                line.substring(2), 
                style: theme.textTheme.bodyMedium?.copyWith(color: subColor, height: 1.6),
              ),
            ),
          ],
        ),
      );
    }

    // الـ Quotes -> شيلت منها اللون الأخضر الدخيل وخليتها Noir بالكامل
    if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6), 
            bottomRight: Radius.circular(6),
          ),
          border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
          color: theme.colorScheme.primary.withOpacity(0.05),
        ),
        child: Text(
          line.substring(2), 
          style: theme.textTheme.bodySmall?.copyWith(color: subColor, height: 1.6),
        ),
      );
    }

    // الـ Horizontal Rule
    if (line.trim() == '---') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: theme.dividerColor.withOpacity(0.3)),
      );
    }

    if (line.trim().isEmpty) return const SizedBox(height: 8);

    // النصوص العادية
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        line, 
        style: theme.textTheme.bodyMedium?.copyWith(color: subColor, height: 1.6),
      ),
    );
  }
}