import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../profile/domain/models/developer_profile.dart';
import '../../../profile/providers/profile_provider.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skills = ref.watch(skillsProvider).asData?.value ?? <DeveloperSkill>[];
    final certs = ref.watch(certificatesProvider).asData?.value ?? <Certificate>[];

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '// knowledge base',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                    ),
                    Text(
                      'Skills & Certs',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showAddDialog(context, isDark),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                      border: Border.all(
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: isDark ? AppTheme.white : AppTheme.black,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
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
                tabs: const [
                  Tab(text: 'SKILLS'),
                  Tab(text: 'CERTIFICATES'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SkillsTab(skills: skills, isDark: isDark),
                _CertsTab(certs: certs, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, bool isDark) {
    final tabIdx = _tabController.index;
    if (tabIdx == 0) {
      _showAddSkillDialog(context, isDark);
    } else {
      _showAddCertDialog(context, isDark);
    }
  }

  void _showAddSkillDialog(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    String category = 'Frontend';
    int proficiency = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (context, setSheetState) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Skill',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.white : AppTheme.black,
                  )),
              const SizedBox(height: 16),
              GlassTextField(controller: nameCtrl, hintText: 'Skill name'),
              const SizedBox(height: 12),
              Row(
                children: ['Frontend', 'Backend', 'Mobile', 'DevOps', 'Other']
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setSheetState(() => category = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: category == cat
                                    ? (isDark ? AppTheme.white : AppTheme.black)
                                    : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  color: category == cat
                                      ? (isDark ? AppTheme.black : AppTheme.white)
                                      : (isDark ? AppTheme.silver : AppTheme.gray),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text('Proficiency: $proficiency/5',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: isDark ? AppTheme.silver : AppTheme.gray,
                  )),
              Slider(
                value: proficiency.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: isDark ? AppTheme.white : AppTheme.black,
                inactiveColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
                onChanged: (v) => setSheetState(() => proficiency = v.round()),
              ),
              const SizedBox(height: 8),
              GlassButton(
                label: 'Add Skill',
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  final skill = DeveloperSkill(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    category: category,
                    proficiency: proficiency,
                    addedAt: DateTime.now(),
                  );
                  await ref.read(profileControllerProvider.notifier).addSkill(skill);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showAddCertDialog(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        blur: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Certificate',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black,
                )),
            const SizedBox(height: 16),
            GlassTextField(controller: titleCtrl, hintText: 'Certificate title'),
            const SizedBox(height: 12),
            GlassTextField(controller: issuerCtrl, hintText: 'Issuer (e.g. Google, Udemy)'),
            const SizedBox(height: 12),
            GlassTextField(
              controller: urlCtrl,
              hintText: 'Credential URL (optional)',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Add Certificate',
              onPressed: () async {
                if (titleCtrl.text.isEmpty || issuerCtrl.text.isEmpty) return;
                final cert = Certificate(
                  id: const Uuid().v4(),
                  title: titleCtrl.text.trim(),
                  issuer: issuerCtrl.text.trim(),
                  credentialUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                  issuedDate: DateTime.now(),
                );
                await ref.read(profileControllerProvider.notifier).addCertificate(cert);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsTab extends ConsumerWidget {
  final List<DeveloperSkill> skills;
  final bool isDark;

  const _SkillsTab({required this.skills, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skills.isEmpty) {
      return _EmptyState(
        icon: Icons.psychology_outlined,
        message: 'No skills yet',
        hint: '// add your expertise',
        isDark: isDark,
      );
    }

    final grouped = <String, List<DeveloperSkill>>{};
    for (final s in skills) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            ...entry.value.map((skill) => Dismissible(
                  key: Key(skill.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>
                      ref.read(profileControllerProvider.notifier).deleteSkill(skill.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill.name,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.white : AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LinearPercentIndicator(
                                  percent: skill.proficiency / 5,
                                  lineHeight: 4,
                                  backgroundColor:
                                      (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                                  progressColor: isDark ? AppTheme.white : AppTheme.black,
                                  barRadius: const Radius.circular(2),
                                  padding: EdgeInsets.zero,
                                  trailing: Text(
                                    '  ${skill.proficiency}/5',
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 10,
                                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

class _CertsTab extends ConsumerWidget {
  final List<Certificate> certs;
  final bool isDark;

  const _CertsTab({required this.certs, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (certs.isEmpty) {
      return _EmptyState(
        icon: Icons.workspace_premium_outlined,
        message: 'No certificates yet',
        hint: '// add your credentials',
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: certs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final cert = certs[i];
        return Dismissible(
          key: Key(cert.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              ref.read(profileControllerProvider.notifier).deleteCertificate(cert.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.workspace_premium_outlined,
                        color: isDark ? AppTheme.white : AppTheme.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert.title,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
                          Text(
                            cert.issuer,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cert.credentialUrl != null)
                      IconButton(
                        onPressed: () => launchUrl(Uri.parse(cert.credentialUrl!)),
                        icon: Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                        ),
                      ),
                  ],
                ),
                if (cert.issuedDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Issued: ${DateFormat('MMM yyyy').format(cert.issuedDate!)}',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: (i * 80).ms),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: isDark ? AppTheme.gray : AppTheme.lightGray),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 12,
              color: isDark ? AppTheme.gray : AppTheme.lightGray,
            ),
          ),
        ],
      ),
    );
  }
}
