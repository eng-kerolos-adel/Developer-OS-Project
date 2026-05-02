import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../profile/domain/models/developer_profile.dart';
import '../../../profile/providers/profile_provider.dart';

class LinksScreen extends ConsumerWidget {
  const LinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final links = ref.watch(linksProvider).asData?.value ?? [];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '// developer links',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                    ),
                    Text(
                      'My Links',
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
                  onTap: () => _showAddLinkDialog(context, ref, isDark),
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
                    child: Icon(Icons.add, size: 20,
                        color: isDark ? AppTheme.white : AppTheme.black),
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 20),

          if (links.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link, size: 48,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray),
                    const SizedBox(height: 16),
                    Text(
                      'No links yet',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '// add your developer profiles',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassButton(
                      label: 'Add Link',
                      width: 160,
                      onPressed: () => _showAddLinkDialog(context, ref, isDark),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: links.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final link = links[i];
                  return Dismissible(
                    key: Key(link.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        ref.read(profileControllerProvider.notifier).deleteLink(link.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    child: GlassCard(
                      onTap: () async {
                        // 1. تنظيف الرابط من أي مسافات زيادة قد تكون دخلت بالخطأ
                        String urlPath = link.url.trim();

                        // 2. التحقق لو الرابط مش بيبدأ بـ http أو https
                        if (!urlPath.startsWith('http://') && !urlPath.startsWith('https://')) {
                          urlPath = 'https://$urlPath'; // إضافة البروتوكول افتراضياً
                        }

                        try {
                          final uri = Uri.parse(urlPath);
                          // 3. محاولة فتح الرابط
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            // إشعار للمستخدم لو الرابط فيه مشكلة هيكلية
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not launch this URL',
                                      style: TextStyle(fontFamily: 'JetBrainsMono',
                                      color: isDark ? AppTheme.white : AppTheme.black)),
                                  backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // التعامل مع الأخطاء غير المتوقعة (مثل كتابة رموز غلط في الرابط)
                          debugPrint('Error launching URL: $e');
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                            ),
                            child: Center(
                              child: _LinkIcon(type: link.type, isDark: isDark),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  link.label,
                                  style: TextStyle(
                                    fontFamily: 'Syne',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.white : AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  link.url,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 11,
                                    color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: link.url));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Link copied!',
                                          style: TextStyle(fontFamily: 'JetBrainsMono',
                                          color: isDark ? AppTheme.white : AppTheme.black)),
                                      backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: isDark ? AppTheme.gray : AppTheme.lightGray,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 80).ms),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddLinkDialog(BuildContext context, WidgetRef ref, bool isDark) {
    String selectedType = 'github';
    final urlCtrl = TextEditingController();
    final labelCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
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
              Text('Add Link',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.white : AppTheme.black,
                  )),
              const SizedBox(height: 16),

              // Link type grid
              SizedBox(
                height: 100,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.5,
                  ),
                  itemCount: AppConstants.linkTypes.length,
                  itemBuilder: (_, i) {
                    final lt = AppConstants.linkTypes[i];
                    final isSelected = selectedType == lt['key'];
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedType = lt['key']!;
                          labelCtrl.text = lt['label']!;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          lt['label']!,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: isSelected
                                ? (isDark ? AppTheme.black : AppTheme.white)
                                : (isDark ? AppTheme.silver : AppTheme.gray),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),
              GlassTextField(controller: labelCtrl, hintText: 'Label (e.g. GitHub)'),
              const SizedBox(height: 10),
              GlassTextField(
                controller: urlCtrl,
                hintText: 'URL',
                keyboardType: TextInputType.url,
                prefixIcon: Icon(Icons.link, size: 16,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray),
              ),
              const SizedBox(height: 16),
              GlassButton(
                label: 'Add Link',
                onPressed: () async {
                  if (urlCtrl.text.isEmpty) return;
                  final link = DeveloperLink(
                    id: const Uuid().v4(),
                    type: selectedType,
                    label: labelCtrl.text.trim().isNotEmpty
                        ? labelCtrl.text.trim()
                        : selectedType,
                    url: urlCtrl.text.trim(),
                  );
                  await ref.read(profileControllerProvider.notifier).saveLink(link);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LinkIcon extends StatelessWidget {
  final String type;
  final bool isDark;

  const _LinkIcon({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.white : AppTheme.black;
    switch (type) {
      case 'github':
        return FaIcon(FontAwesomeIcons.github, size: 20, color: color);
      case 'linkedin':
        return FaIcon(FontAwesomeIcons.linkedin, size: 20, color: color);
      case 'twitter':
        return FaIcon(FontAwesomeIcons.xTwitter, size: 20, color: color);
      case 'stackoverflow':
        return FaIcon(FontAwesomeIcons.stackOverflow, size: 20, color: color);
      case 'youtube':
        return FaIcon(FontAwesomeIcons.youtube, size: 20, color: color);
      case 'discord':
        return FaIcon(FontAwesomeIcons.discord, size: 20, color: color);
      case 'telegram':
        return FaIcon(FontAwesomeIcons.telegram, size: 20, color: color);
      case 'email':
        return Icon(Icons.email_outlined, size: 20, color: color);
      default:
        return Icon(Icons.link, size: 20, color: color);
    }
  }
}
