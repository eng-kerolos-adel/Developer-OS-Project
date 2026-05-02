// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:percent_indicator/percent_indicator.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../../../core/constants/route_constants.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/glass_widgets.dart';
// import '../../../auth/providers/auth_provider.dart';
// import '../../../profile/providers/profile_provider.dart';

// class ProfileScreen extends ConsumerWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final profile = ref.watch(profileProvider).asData?.value;
//     final user = ref.watch(currentUserProvider);
//     final skills = ref.watch(skillsProvider).asData?.value ?? [];
//     final certs = ref.watch(certificatesProvider).asData?.value ?? [];

//     final name = profile?.name ?? user?.displayName ?? 'Developer';
//     final photoUrl = profile?.photoURL ?? user?.photoURL;

//     return SafeArea(
//       child: CustomScrollView(
//         physics: const BouncingScrollPhysics(),
//         slivers: [
//           // Header
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '// profile',
//                     style: TextStyle(
//                       fontFamily: 'JetBrainsMono',
//                       fontSize: 12,
//                       color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => context.go(RouteConstants.editProfile),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
//                         border: Border.all(
//                           color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
//                         ),
//                       ),
//                       child: Text(
//                         'EDIT',
//                         style: TextStyle(
//                           fontFamily: 'JetBrainsMono',
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: isDark ? AppTheme.white : AppTheme.black,
//                           letterSpacing: 1.5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ).animate().fadeIn(delay: 100.ms),
//           ),

//           // Profile card
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//               child: GlassCard(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     // Avatar
//                     Stack(
//                       alignment: Alignment.bottomRight,
//                       children: [
//                         Container(
//                           width: 90,
//                           height: 90,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
//                             border: Border.all(
//                               color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.15),
//                               width: 1,
//                             ),
//                           ),
//                           child: ClipOval(
//                             child: photoUrl != null
//                                 ? CachedNetworkImage(
//                                     imageUrl: photoUrl,
//                                     fit: BoxFit.cover,
//                                     placeholder: (_, __) => Icon(
//                                       Icons.person,
//                                       size: 40,
//                                       color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                                     ),
//                                   )
//                                 : Icon(
//                                     Icons.person,
//                                     size: 40,
//                                     color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                                   ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Name
//                     Text(
//                       name,
//                       style: TextStyle(
//                         fontFamily: 'Syne',
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                         color: isDark ? AppTheme.white : AppTheme.black,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),

//                     if (profile?.specialization != null) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         profile!.specialization!,
//                         style: TextStyle(
//                           fontFamily: 'JetBrainsMono',
//                           fontSize: 13,
//                           color: isDark ? AppTheme.silver : AppTheme.gray,
//                         ),
//                       ),
//                     ],

//                     if (profile?.experienceLevel != null) ...[
//                       const SizedBox(height: 6),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(6),
//                           color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
//                         ),
//                         child: Text(
//                           profile!.experienceLevel,
//                           style: TextStyle(
//                             fontFamily: 'JetBrainsMono',
//                             fontSize: 11,
//                             color: isDark ? AppTheme.silver : AppTheme.gray,
//                           ),
//                         ),
//                       ),
//                     ],

//                     if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
//                       const SizedBox(height: 14),
//                       Text(
//                         profile.bio!,
//                         style: TextStyle(
//                           fontFamily: 'JetBrainsMono',
//                           fontSize: 12,
//                           color: isDark ? AppTheme.lightGray : AppTheme.gray,
//                           height: 1.6,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],

//                     if (profile?.location != null || profile?.website != null) ...[
//                       const SizedBox(height: 14),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           if (profile?.location != null) ...[
//                             Icon(
//                               Icons.location_on_outlined,
//                               size: 13,
//                               color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               profile!.location!,
//                               style: TextStyle(
//                                 fontFamily: 'JetBrainsMono',
//                                 fontSize: 11,
//                                 color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                           ],
//                           if (profile?.website != null) ...[
//                             IconButton(
//                               // onPressed: () async {
//                               //   final uri = Uri.parse(profile!.website!);
//                               //   if (await canLaunchUrl(uri)) {
//                               //     await launchUrl(uri, mode: LaunchMode.externalApplication);
//                               //   }
//                               // },
//                               onPressed: () async {
//                                 String urlPath = profile!.website!.trim();
//                                 if (!urlPath.startsWith('http://') && !urlPath.startsWith('https://')) {
//                                   urlPath = 'https://$urlPath';
//                                 }
//                                 try {
//                                   final uri = Uri.parse(urlPath);
//                                   if (await canLaunchUrl(uri)) {
//                                     await launchUrl(uri, mode: LaunchMode.externalApplication);
//                                   }
//                                 } catch (e) {
//                                   debugPrint('Error launching URL: $e');
//                                 }
//                               },
//                               icon: Row(
//                                 mainAxisSize: MainAxisSize.min, 
//                                 children: [
//                                   Icon(
//                                     Icons.link,
//                                     size: 13,
//                                     color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     profile!.website!,
//                                     style: TextStyle(
//                                       fontFamily: 'JetBrainsMono',
//                                       fontSize: 11,
//                                       color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
//           ),

//           // Tech skills
//           if (profile?.techSkills != null && profile!.techSkills.isNotEmpty) ...[
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Tech Stack',
//                       style: TextStyle(
//                         fontFamily: 'Syne',
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: isDark ? AppTheme.white : AppTheme.black,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     GlassCard(
//                       child: Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: profile.techSkills
//                             .map((tech) => Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8),
//                                     color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
//                                     border: Border.all(
//                                       color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     tech,
//                                     style: TextStyle(
//                                       fontFamily: 'JetBrainsMono',
//                                       fontSize: 12,
//                                       color: isDark ? AppTheme.silver : AppTheme.gray,
//                                     ),
//                                   ),
//                                 ))
//                             .toList(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ).animate().fadeIn(delay: 350.ms),
//             ),
//           ],

//           // Skills summary
//           if (skills.isNotEmpty) ...[
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Skills (${skills.length})',
//                       style: TextStyle(
//                         fontFamily: 'Syne',
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: isDark ? AppTheme.white : AppTheme.black,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     GlassCard(
//                       child: Column(
//                         children: skills
//                             .take(5)
//                             .map((s) => Padding(
//                                   padding: const EdgeInsets.only(bottom: 12),
//                                   child: Row(
//                                     children: [
//                                       Expanded(
//                                         flex: 3,
//                                         child: Text(
//                                           s.name,
//                                           style: TextStyle(
//                                             fontFamily: 'JetBrainsMono',
//                                             fontSize: 12,
//                                             color: isDark ? AppTheme.white : AppTheme.black,
//                                           ),
//                                         ),
//                                       ),
//                                       Expanded(
//                                         flex: 5,
//                                         child: LinearPercentIndicator(
//                                           percent: s.proficiency / 5,
//                                           lineHeight: 4,
//                                           backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
//                                           progressColor: isDark ? AppTheme.white : AppTheme.black,
//                                           barRadius: const Radius.circular(2),
//                                           padding: EdgeInsets.zero,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Text(
//                                         '${s.proficiency}/5',
//                                         style: TextStyle(
//                                           fontFamily: 'JetBrainsMono',
//                                           fontSize: 10,
//                                           color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ))
//                             .toList(),
//                       ),
//                     ),
//                   ],
//                 ),
//               ).animate().fadeIn(delay: 450.ms),
//             ),
//           ],

//           // Certificates count
//           if (certs.isNotEmpty)
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//                 child: GlassCard(
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 44,
//                         height: 44,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(10),
//                           color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
//                         ),
//                         child: Icon(
//                           Icons.workspace_premium_outlined,
//                           color: isDark ? AppTheme.white : AppTheme.black,
//                           size: 22,
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '${certs.length} Certificates',
//                             style: TextStyle(
//                               fontFamily: 'Syne',
//                               fontSize: 16,
//                               fontWeight: FontWeight.w700,
//                               color: isDark ? AppTheme.white : AppTheme.black,
//                             ),
//                           ),
//                           Text(
//                             '// verified credentials',
//                             style: TextStyle(
//                               fontFamily: 'JetBrainsMono',
//                               fontSize: 11,
//                               color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ).animate().fadeIn(delay: 500.ms),
//             ),

//           const SliverToBoxAdapter(child: SizedBox(height: 32)),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:developer_os/core/constants/route_constants.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/profile/providers/profile_provider.dart';
import 'package:developer_os/features/projects/providers/project_provider.dart';
import 'package:developer_os/features/export/pdf_exporter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).asData?.value;
    final user = ref.watch(currentUserProvider);
    final skills = ref.watch(skillsProvider).asData?.value ?? [];
    final certs = ref.watch(certificatesProvider).asData?.value ?? [];

    final name = profile?.name ?? user?.displayName ?? 'Developer';
    final photoUrl = profile?.photoURL ?? user?.photoURL;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '// profile',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(RouteConstants.editProfile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        border: Border.all(
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        'EDIT',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
          ),

          // Profile card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                            border: Border.all(
                              color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: photoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Icon(
                                      Icons.person,
                                      size: 40,
                                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 40,
                                    color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (profile?.specialization != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile!.specialization!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                          color: isDark ? AppTheme.silver : AppTheme.gray,
                        ),
                      ),
                    ],

                    if (profile?.experienceLevel != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        ),
                        child: Text(
                          profile!.experienceLevel,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: isDark ? AppTheme.silver : AppTheme.gray,
                          ),
                        ),
                      ),
                    ],

                    if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        profile.bio!,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: isDark ? AppTheme.lightGray : AppTheme.gray,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    if (profile?.location != null || profile?.website != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (profile?.location != null) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile!.location!,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 10,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (profile?.website != null) ...[
                            IconButton(
                              // onPressed: () async {
                              //   final uri = Uri.parse(profile!.website!);
                              //   if (await canLaunchUrl(uri)) {
                              //     await launchUrl(uri, mode: LaunchMode.externalApplication);
                              //   }
                              // },
                              onPressed: () async {
                                String urlPath = profile!.website!.trim();
                                if (!urlPath.startsWith('http://') && !urlPath.startsWith('https://')) {
                                  urlPath = 'https://$urlPath';
                                }
                                try {
                                  final uri = Uri.parse(urlPath);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                } catch (e) {
                                  debugPrint('Error launching URL: $e');
                                }
                              },
                              icon: Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 12,
                                    color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile!.website!,
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 10,
                                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ),

          // Tech skills
          if (profile?.techSkills != null && profile!.techSkills.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tech Stack',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.techSkills
                            .map((tech) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                                    border: Border.all(
                                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    tech,
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 12,
                                      color: isDark ? AppTheme.silver : AppTheme.gray,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms),
            ),
          ],

          // Skills summary
          if (skills.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills (${skills.length})',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        children: skills
                            .take(5)
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          s.name,
                                          style: TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: 12,
                                            color: isDark ? AppTheme.white : AppTheme.black,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: LinearPercentIndicator(
                                          percent: s.proficiency / 5,
                                          lineHeight: 4,
                                          backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                                          progressColor: isDark ? AppTheme.white : AppTheme.black,
                                          barRadius: const Radius.circular(2),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${s.proficiency}/5',
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 10,
                                          color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 450.ms),
            ),
          ],

          // Certificates count
          if (certs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                        ),
                        child: Icon(
                          Icons.workspace_premium_outlined,
                          color: isDark ? AppTheme.white : AppTheme.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${certs.length} Certificates',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
                          Text(
                            '// verified credentials',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: isDark ? AppTheme.gray : AppTheme.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),

          // Export PDF
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GlassButton(
                label: '📄 Export Portfolio PDF',
                isPrimary: false,
                onPressed: () async {
                  if (profile == null) return;
                  final projects = ref.read(projectsProvider).asData?.value ?? [];
                  await PortfolioPDFExporter.export(
                    profile: profile,
                    skills: skills,
                    projects: projects,
                    certs: certs,
                    links: ref.read(linksProvider).asData?.value ?? [],
                    techStacks: profile.techSkills
                  );
                },
              ),
            ).animate().fadeIn(delay: 550.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}