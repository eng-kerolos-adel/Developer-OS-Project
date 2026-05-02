import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:developer_os/core/constants/app_constants.dart';
import 'package:developer_os/core/constants/route_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';
import 'package:developer_os/features/ai/services/ai_provider.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _demoCtrl = TextEditingController();

  String _projectType = AppConstants.projectTypes.first;
  String _platform = AppConstants.targetPlatforms.first;
  List<String> _selectedTechs = [];
  bool _createGitHubRepo = false;
  bool _isPrivateRepo = false;
  bool _aiLoading = false;

  String? _editProjectId; // بنعرف متغير يشيل الـ id

  @override
  void initState() {
    super.initState();

    // بنستنى أول Frame عشان نقرأ الـ URL بأمان
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      _editProjectId = state.uri.queryParameters['editId'];

      // لو الـ id موجود، يعني إحنا في وضع التعديل
      if (_editProjectId != null) {
        final projects = ref.read(projectsProvider).value ?? [];
        final project = projects.firstWhere((p) => p.id == _editProjectId);

        // بنملا الـ Controllers بتاعتك بالداتا القديمة
        setState(() {
          _nameCtrl.text = project.name;
          _descCtrl.text = project.description;
          _githubCtrl.text = project.githubUrl ?? '';
          _demoCtrl.text = project.demoUrl ?? '';
          _projectType = project.projectType;
          _platform = project.targetPlatform;
          _selectedTechs = List<String>.from(project.techStack);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _githubCtrl.dispose();
    _demoCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a project name first')),
      );
      return;
    }

    final aiService = ref.read(aiServiceProvider);
    if (aiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI not configured. Add API key in Settings.'),
          action: SnackBarAction(label: 'Settings', onPressed: () {}),
        ),
      );
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final profile = ref.read(profileProvider).asData?.value;
      final result = await aiService.generateProjectDetails(
        projectName: _nameCtrl.text.trim(),
        specialization: profile?.specialization,
        existingTechs: profile?.techSkills,
      );

      setState(() {
        if (result['description'] != null) {
          _descCtrl.text = result['description'];
        }
        if (result['tech_stack'] != null) {
          _selectedTechs = List<String>.from(result['tech_stack'])
              .where((t) => AppConstants.allTechs.contains(t))
              .toList();
        }
        if (result['project_type'] != null &&
            AppConstants.projectTypes.contains(result['project_type'])) {
          _projectType = result['project_type'];
        }
        if (result['target_platform'] != null &&
            AppConstants.targetPlatforms.contains(result['target_platform'])) {
          _platform = result['target_platform'];
        }
        _aiLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ AI generated project details!')),
        );
      }
    } catch (e) {
      setState(() => _aiLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI generation failed. Try again.')),
        );
      }
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTechs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one technology')),
      );
      return;
    }

    String? githubUrl = _githubCtrl.text.trim().isNotEmpty
        ? _githubCtrl.text.trim()
        : null;

    // Create GitHub repo if enabled
    if (_createGitHubRepo) {
      final repoUrl = await ref
          .read(createGitHubRepoProvider.notifier)
          .createRepo(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            isPrivate: _isPrivateRepo,
          );
      if (repoUrl != null) {
        githubUrl = repoUrl;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ GitHub repo created: $repoUrl')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('GitHub repo creation failed. Continuing...')),
          );
        }
      }
    }

    // 💡 هنا الشغل كله:
  if (_editProjectId != null) {
    // 1. هنجيب بيانات المشروع الأصلي عشان نعمل منه نسخة جديدة
    final projects = ref.read(projectsProvider).value ?? [];
    final oldProject = projects.firstWhere((p) => p.id == _editProjectId);

    final updatedProject = oldProject.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      techStack: _selectedTechs,
      projectType: _projectType,
      targetPlatform: _platform,
      githubUrl: _githubCtrl.text.trim().isNotEmpty ? _githubCtrl.text.trim() : null,
      demoUrl: _demoCtrl.text.trim().isNotEmpty ? _demoCtrl.text.trim() : null,
    );

    // 2. بنادي على ميثود التعديل بتاعتك اللي أنت لسه كاتبها 🔥
    await ref.read(projectControllerProvider.notifier).updateProject(updatedProject);
    
    // بنرجعه لصفحة التفاصيل بعد التعديل
    if (mounted) {
      context.go(RouteConstants.projectDetail(_editProjectId!));
    }

    } else {
      final id = await ref.read(projectControllerProvider.notifier).createProject(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          techStack: _selectedTechs,
          projectType: _projectType,
          targetPlatform: _platform,
          githubUrl: githubUrl,
          demoUrl: _demoCtrl.text.trim().isNotEmpty ? _demoCtrl.text.trim() : null,
        );

      if (id != null && mounted) {
        context.go(RouteConstants.projectDetail(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(projectControllerProvider).isLoading;
    final githubToken = ref.watch(githubTokenProvider);
    final aiKey = ref.watch(aiApiKeyProvider);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.go(RouteConstants.projects),
                      child: Icon(Icons.arrow_back_ios,
                          color: isDark ? AppTheme.white : AppTheme.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('// init project',
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      Text('Create Project',
                          style: TextStyle(fontFamily: 'Syne', fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.white : AppTheme.black)),
                    ]),
                  ]).animate().fadeIn(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Step 1: Project Info
                      _StepHeader(step: 1, title: 'Project Info', isDark: isDark),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _nameCtrl,
                        hintText: 'Project name',
                        prefixIcon: Icon(Icons.folder_outlined, size: 16,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 10),

                      // AI Generate button
                      Row(children: [
                        Expanded(
                          child: GlassTextField(
                            controller: _descCtrl,
                            hintText: 'Project description...',
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),

                      // AI Button
                      GlassButton(
                        label: aiKey != null ? '✨ Generate with AI' : '✨ AI (Add key in Settings)',
                        isPrimary: false,
                        isLoading: _aiLoading,
                        onPressed: aiKey != null ? _generateWithAI : null,
                        icon: _aiLoading ? null : const Text('✨', style: TextStyle(fontSize: 14)),
                      ),

                      const SizedBox(height: 24),

                      // Step 2: Project Type
                      _StepHeader(step: 2, title: 'Project Type', isDark: isDark),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: AppConstants.projectTypes.map((type) => GestureDetector(
                          onTap: () => setState(() => _projectType = type),
                          child: _SelectChip(label: type, selected: _projectType == type, isDark: isDark),
                        )).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Step 3: Platform
                      _StepHeader(step: 3, title: 'Target Platform', isDark: isDark),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: AppConstants.targetPlatforms.map((p) => GestureDetector(
                          onTap: () => setState(() => _platform = p),
                          child: _SelectChip(label: p, selected: _platform == p, isDark: isDark),
                        )).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Step 4: Tech Stack
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _StepHeader(step: 4, title: 'Tech Stack', isDark: isDark),
                        Text('${_selectedTechs.length} selected',
                            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      ]),
                      const SizedBox(height: 4),
                      Text('// roadmap auto-generated from stack',
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      const SizedBox(height: 12),
                      ..._buildTechGroup('Frontend', AppConstants.frontendTechs, isDark),
                      ..._buildTechGroup('Backend', AppConstants.backendTechs, isDark),
                      ..._buildTechGroup('Mobile', AppConstants.mobileTechs, isDark),
                      ..._buildTechGroup('Database', AppConstants.dbTechs, isDark),
                      ..._buildTechGroup('DevOps', AppConstants.devOpsTechs, isDark),

                      const SizedBox(height: 24),

                      // Step 5: Links
                      _StepHeader(step: 5, title: 'Links (Optional)', isDark: isDark),
                      const SizedBox(height: 12),
                      GlassTextField(
                        controller: _githubCtrl,
                        hintText: 'GitHub URL (auto-filled if GitHub connected)',
                        prefixIcon: Icon(Icons.code, size: 16,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                      ),
                      const SizedBox(height: 10),
                      GlassTextField(
                        controller: _demoCtrl,
                        hintText: 'Demo/Live URL',
                        prefixIcon: Icon(Icons.link, size: 16,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                      ),

                      const SizedBox(height: 24),

                      // Step 6: GitHub Integration
                      _StepHeader(step: 6, title: 'GitHub Repo', isDark: isDark),
                      const SizedBox(height: 12),

                      if (githubToken != null) ...[
                        GlassCard(
                          child: Column(children: [
                            Row(children: [
                              Icon(Icons.add_circle_outline, size: 20,
                                  color: isDark ? AppTheme.white : AppTheme.black),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Auto-create GitHub Repo',
                                        style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.white : AppTheme.black)),
                                    Text('Creates a new repo on your GitHub account',
                                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                                  ])),
                              Switch(
                                value: _createGitHubRepo,
                                activeColor: isDark ? AppTheme.white : AppTheme.black,
                                onChanged: (v) => setState(() => _createGitHubRepo = v),
                              ),
                            ]),
                            if (_createGitHubRepo) ...[
                              const SizedBox(height: 12),
                              Divider(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.lock_outline, size: 16,
                                    color: isDark ? AppTheme.gray : AppTheme.lightGray),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Private repository',
                                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                                        color: isDark ? AppTheme.silver : AppTheme.gray))),
                                Switch(
                                  value: _isPrivateRepo,
                                  activeColor: isDark ? AppTheme.white : AppTheme.black,
                                  onChanged: (v) => setState(() => _isPrivateRepo = v),
                                ),
                              ]),
                            ],
                          ]),
                        ),
                      ] else ...[
                        GlassCard(
                          child: Row(children: [
                            Icon(Icons.info_outline, size: 18,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray),
                            const SizedBox(width: 12),
                            Expanded(child: Text(
                                'Connect GitHub in Settings to auto-create repos',
                                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                                    color: isDark ? AppTheme.gray : AppTheme.lightGray))),
                          ]),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Info card
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Icon(Icons.auto_awesome_outlined, size: 20,
                              color: isDark ? AppTheme.silver : AppTheme.gray),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto Roadmap',
                                    style: TextStyle(fontFamily: 'Syne', fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppTheme.white : AppTheme.black)),
                                Text('Week-by-week roadmap generated from your tech stack.',
                                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                        color: isDark ? AppTheme.gray : AppTheme.lightGray, height: 1.4)),
                              ])),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      GlassButton(
                        label: _editProjectId != null
                            ? 'Save Changes' // 📝 لو بنعدل، ده النص اللي هيظهر
                            : (_createGitHubRepo
                                ? 'Create Project + GitHub Repo' // 🆕 لو إنشاء والـ GitHub شغال
                                : 'Create + Generate Roadmap'), // 🆕 لو إنشاء عادي (الكود بتاعك)
                        onPressed: _create,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTechGroup(String label, List<String> techs, bool isDark) {
    return [
      Text(label.toUpperCase(),
          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.gray : AppTheme.lightGray, letterSpacing: 2)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: techs.map((tech) {
          final selected = _selectedTechs.contains(tech);
          return GestureDetector(
            onTap: () => setState(() => selected ? _selectedTechs.remove(tech) : _selectedTechs.add(tech)),
            child: _SelectChip(label: tech, selected: selected, isDark: isDark),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
    ];
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final String title;
  final bool isDark;
  const _StepHeader({required this.step, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(shape: BoxShape.circle,
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
            border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2))),
        child: Center(child: Text('$step',
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.white : AppTheme.black))),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.white : AppTheme.black)),
    ]);
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  const _SelectChip({required this.label, required this.selected, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: selected ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
        border: Border.all(color: selected ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
              color: selected ? (isDark ? AppTheme.black : AppTheme.white) : (isDark ? AppTheme.silver : AppTheme.gray),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
    );
  }
}