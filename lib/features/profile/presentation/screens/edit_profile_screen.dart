// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:uuid/uuid.dart';

// import '../../../../core/constants/app_constants.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/glass_widgets.dart';
// import '../../../auth/providers/auth_provider.dart';
// import '../../../profile/domain/models/developer_profile.dart';
// import '../../../profile/providers/profile_provider.dart';

// class EditProfileScreen extends ConsumerStatefulWidget {
//   const EditProfileScreen({super.key});

//   @override
//   ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _bioController = TextEditingController();
//   final _locationController = TextEditingController();
//   final _websiteController = TextEditingController();
//   String _selectedSpecialization = AppConstants.specializations.first;
//   String _selectedLevel = AppConstants.experienceLevels.first;
//   List<String> _selectedTechs = [];
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final profile = ref.read(profileProvider).asData?.value;
//       if (profile != null) {
//         _nameController.text = profile.name;
//         _bioController.text = profile.bio ?? '';
//         _locationController.text = profile.location ?? '';
//         _websiteController.text = profile.website ?? '';
//         _selectedSpecialization =
//             profile.specialization ?? AppConstants.specializations.first;
//         _selectedLevel = profile.experienceLevel;
//         _selectedTechs = List.from(profile.techSkills);
//         setState(() {});
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _bioController.dispose();
//     _locationController.dispose();
//     _websiteController.dispose();
//     super.dispose();
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);

//     final user = ref.read(currentUserProvider);
//     if (user == null) return;

//     final profile = DeveloperProfile(
//       uid: user.uid,
//       name: _nameController.text.trim(),
//       email: user.email ?? '',
//       bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
//       location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
//       website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
//       specialization: _selectedSpecialization,
//       experienceLevel: _selectedLevel,
//       techSkills: _selectedTechs,
//       photoURL: user.photoURL,
//       createdAt: DateTime.now(),
//     );

//     await ref.read(profileControllerProvider.notifier).saveProfile(profile);
//     setState(() => _loading = false);
//     if (mounted) context.pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: CustomScrollView(
//             physics: const BouncingScrollPhysics(),
//             slivers: [
//               // Header
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => context.pop(),
//                         child: Icon(
//                           Icons.arrow_back_ios,
//                           color: isDark ? AppTheme.white : AppTheme.black,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Edit Profile',
//                         style: TextStyle(
//                           fontFamily: 'Syne',
//                           fontSize: 22,
//                           fontWeight: FontWeight.w700,
//                           color: isDark ? AppTheme.white : AppTheme.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ).animate().fadeIn(),
//               ),

//               const SliverToBoxAdapter(child: SizedBox(height: 24)),

//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _Label('Full Name', isDark),
//                       const SizedBox(height: 8),
//                       GlassTextField(
//                         controller: _nameController,
//                         hintText: 'John Doe',
//                         validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
//                       ),

//                       const SizedBox(height: 16),
//                       _Label('Bio', isDark),
//                       const SizedBox(height: 8),
//                       GlassTextField(
//                         controller: _bioController,
//                         hintText: 'Tell the world about yourself...',
//                         maxLines: 3,
//                       ),

//                       const SizedBox(height: 16),
//                       _Label('Specialization', isDark),
//                       const SizedBox(height: 8),
//                       GlassCard(
//                         padding: EdgeInsets.zero,
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: _selectedSpecialization,
//                             isExpanded: true,
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
//                             style: TextStyle(
//                               fontFamily: 'JetBrainsMono',
//                               fontSize: 13,
//                               color: isDark ? AppTheme.white : AppTheme.black,
//                             ),
//                             items: AppConstants.specializations
//                                 .map((s) => DropdownMenuItem(value: s, child: Text(s)))
//                                 .toList(),
//                             onChanged: (v) => setState(() => _selectedSpecialization = v!),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),
//                       _Label('Experience Level', isDark),
//                       const SizedBox(height: 8),
//                       GlassCard(
//                         padding: EdgeInsets.zero,
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: _selectedLevel,
//                             isExpanded: true,
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
//                             style: TextStyle(
//                               fontFamily: 'JetBrainsMono',
//                               fontSize: 13,
//                               color: isDark ? AppTheme.white : AppTheme.black,
//                             ),
//                             items: AppConstants.experienceLevels
//                                 .map((l) => DropdownMenuItem(value: l, child: Text(l)))
//                                 .toList(),
//                             onChanged: (v) => setState(() => _selectedLevel = v!),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),
//                       _Label('Location', isDark),
//                       const SizedBox(height: 8),
//                       GlassTextField(
//                         controller: _locationController,
//                         hintText: 'e.g. Cairo, Egypt',
//                         prefixIcon: Icon(Icons.location_on_outlined, size: 16,
//                             color: isDark ? AppTheme.gray : AppTheme.lightGray),
//                       ),

//                       const SizedBox(height: 16),
//                       _Label('Website', isDark),
//                       const SizedBox(height: 8),
//                       GlassTextField(
//                         controller: _websiteController,
//                         hintText: 'https://yoursite.com',
//                         keyboardType: TextInputType.url,
//                         prefixIcon: Icon(Icons.link, size: 16,
//                             color: isDark ? AppTheme.gray : AppTheme.lightGray),
//                       ),

//                       const SizedBox(height: 24),

//                       // Tech stack selector
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _Label('Tech Stack', isDark),
//                           Text(
//                             '${_selectedTechs.length} selected',
//                             style: TextStyle(
//                               fontFamily: 'JetBrainsMono',
//                               fontSize: 11,
//                               color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       ..._buildTechSection('Frontend', AppConstants.frontendTechs, isDark),
//                       ..._buildTechSection('Backend', AppConstants.backendTechs, isDark),
//                       ..._buildTechSection('Mobile', AppConstants.mobileTechs, isDark),
//                       ..._buildTechSection('Database', AppConstants.dbTechs, isDark),
//                       ..._buildTechSection('DevOps', AppConstants.devOpsTechs, isDark),

//                       const SizedBox(height: 32),

//                       GlassButton(
//                         label: 'Save Profile',
//                         onPressed: _save,
//                         isLoading: _loading,
//                       ),

//                       const SizedBox(height: 32),
//                     ],
//                   ).animate().fadeIn(delay: 200.ms),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildTechSection(String title, List<String> techs, bool isDark) {
//     return [
//       Text(
//         title,
//         style: TextStyle(
//           fontFamily: 'JetBrainsMono',
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: isDark ? AppTheme.gray : AppTheme.lightGray,
//           letterSpacing: 1.5,
//         ),
//       ),
//       const SizedBox(height: 8),
//       Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         children: techs.map((tech) {
//           final selected = _selectedTechs.contains(tech);
//           return GestureDetector(
//             onTap: () {
//               setState(() {
//                 if (selected) {
//                   _selectedTechs.remove(tech);
//                 } else {
//                   _selectedTechs.add(tech);
//                 }
//               });
//             },
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 color: selected
//                     ? (isDark ? AppTheme.white : AppTheme.black)
//                     : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
//                 border: Border.all(
//                   color: selected
//                       ? (isDark ? AppTheme.white : AppTheme.black)
//                       : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.12),
//                 ),
//               ),
//               child: Text(
//                 tech,
//                 style: TextStyle(
//                   fontFamily: 'JetBrainsMono',
//                   fontSize: 12,
//                   color: selected
//                       ? (isDark ? AppTheme.black : AppTheme.white)
//                       : (isDark ? AppTheme.silver : AppTheme.gray),
//                   fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//       const SizedBox(height: 16),
//     ];
//   }
// }

// class _Label extends StatelessWidget {
//   final String text;
//   final bool isDark;

//   const _Label(this.text, this.isDark);

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontFamily: 'JetBrainsMono',
//         fontSize: 12,
//         fontWeight: FontWeight.w700,
//         color: isDark ? AppTheme.silver : AppTheme.gray,
//         letterSpacing: 1,
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import 'package:developer_os/core/constants/app_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/profile/domain/models/developer_profile.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';
import 'package:developer_os/features/ai/services/ai_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  String _selectedSpecialization = AppConstants.specializations.first;
  String _selectedLevel = AppConstants.experienceLevels.first;
  List<String> _selectedTechs = [];
  bool _loading = false;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).asData?.value;
      if (profile != null) {
        _nameController.text = profile.name;
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
        _websiteController.text = profile.website ?? '';
        _selectedSpecialization =
            profile.specialization ?? AppConstants.specializations.first;
        _selectedLevel = profile.experienceLevel;
        _selectedTechs = List.from(profile.techSkills);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // =====================
  // AI Bio Generator
  // =====================
  Future<void> _generateBioWithAI() async {
    final aiService = ref.read(aiServiceProvider);

    if (aiService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'AI not configured. Add Gemini API key in Settings.',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty && _selectedTechs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Add your name and tech stack first.',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final prompt = '''
        Write a professional developer bio for:
        - Name: ${name.isNotEmpty ? name : 'Developer'}
        - Specialization: $_selectedSpecialization
        - Experience level: $_selectedLevel
        - Tech stack: ${_selectedTechs.isNotEmpty ? _selectedTechs.join(', ') : 'Various technologies'}
        ${_locationController.text.isNotEmpty ? '- Location: ${_locationController.text}' : ''}

        Write 2-3 sentences maximum. First person voice. Professional but friendly tone. 
        Focus on what they build and their expertise. No emojis. No quotes around the text.
        Just the bio text directly.
        ''';

      final bio = await aiService.generateBio(prompt);

      if (mounted && bio.isNotEmpty) {
        setState(() {
          _bioController.text = bio.trim();
          _aiLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✨ Bio generated! Edit it to your liking.',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _aiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI failed: ${e.toString()}',
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profile = DeveloperProfile(
      uid: user.uid,
      name: _nameController.text.trim(),
      email: user.email ?? '',
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      specialization: _selectedSpecialization,
      experienceLevel: _selectedLevel,
      techSkills: _selectedTechs,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
    );

    await ref.read(profileControllerProvider.notifier).saveProfile(profile);
    setState(() => _loading = false);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: isDark ? AppTheme.white : AppTheme.black,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Full Name', isDark),
                      const SizedBox(height: 8),
                      GlassTextField(
                        controller: _nameController,
                        hintText: 'John Doe',
                        validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Label('Bio', isDark),
                          GestureDetector(
                            onTap: _aiLoading ? null : _generateBioWithAI,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: (isDark ? AppTheme.white : AppTheme.black)
                                    .withOpacity(0.07),
                                border: Border.all(
                                    color: (isDark ? AppTheme.white : AppTheme.black)
                                        .withOpacity(0.15)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                _aiLoading
                                    ? SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: isDark ? AppTheme.white : AppTheme.black,
                                        ),
                                      )
                                    : Text('✨',
                                        style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 5),
                                Text(
                                  _aiLoading ? 'Writing...' : 'AI Write Bio',
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 11,
                                    color: isDark ? AppTheme.silver : AppTheme.gray,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GlassTextField(
                        controller: _bioController,
                        hintText: 'Tell the world about yourself...',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),
                      _Label('Specialization', isDark),
                      const SizedBox(height: 8),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSpecialization,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                            items: AppConstants.specializations
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedSpecialization = v!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _Label('Experience Level', isDark),
                      const SizedBox(height: 8),
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLevel,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                            items: AppConstants.experienceLevels
                                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedLevel = v!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      _Label('Location', isDark),
                      const SizedBox(height: 8),
                      GlassTextField(
                        controller: _locationController,
                        hintText: 'e.g. Cairo, Egypt',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 16,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                      ),

                      const SizedBox(height: 16),
                      _Label('Website', isDark),
                      const SizedBox(height: 8),
                      GlassTextField(
                        controller: _websiteController,
                        hintText: 'https://yoursite.com',
                        keyboardType: TextInputType.url,
                        prefixIcon: Icon(Icons.link, size: 16,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray),
                      ),

                      const SizedBox(height: 24),

                      // Tech stack selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Label('Tech Stack', isDark),
                          Text(
                            '${_selectedTechs.length} selected',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ..._buildTechSection('Frontend', AppConstants.frontendTechs, isDark),
                      ..._buildTechSection('Backend', AppConstants.backendTechs, isDark),
                      ..._buildTechSection('Mobile', AppConstants.mobileTechs, isDark),
                      ..._buildTechSection('Database', AppConstants.dbTechs, isDark),
                      ..._buildTechSection('DevOps', AppConstants.devOpsTechs, isDark),

                      const SizedBox(height: 32),

                      GlassButton(
                        label: 'Save Profile',
                        onPressed: _save,
                        isLoading: _loading,
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

  List<Widget> _buildTechSection(String title, List<String> techs, bool isDark) {
    return [
      Text(
        title,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.gray : AppTheme.lightGray,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: techs.map((tech) {
          final selected = _selectedTechs.contains(tech);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedTechs.remove(tech);
                } else {
                  _selectedTechs.add(tech);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selected
                    ? (isDark ? AppTheme.white : AppTheme.black)
                    : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
                border: Border.all(
                  color: selected
                      ? (isDark ? AppTheme.white : AppTheme.black)
                      : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.12),
                ),
              ),
              child: Text(
                tech,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: selected
                      ? (isDark ? AppTheme.black : AppTheme.white)
                      : (isDark ? AppTheme.silver : AppTheme.gray),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
    ];
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;

  const _Label(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.silver : AppTheme.gray,
        letterSpacing: 1,
      ),
    );
  }
}