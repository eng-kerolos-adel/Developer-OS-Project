import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/snippets/providers/snippets_provider.dart';
import 'package:developer_os/features/snippets/domain/models/code_snippet.dart';
import '../../../ai/services/ai_provider.dart';

class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});

  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  String _search = '';
  String _filterLang = 'all';
  bool _favOnly = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSnippets = ref.watch(snippetsProvider).asData?.value ?? [];

    final filtered = allSnippets.where((s) {
      final matchSearch = _search.isEmpty ||
          s.title.toLowerCase().contains(_search.toLowerCase()) ||
          s.code.toLowerCase().contains(_search.toLowerCase()) ||
          s.tags.any((t) => t.toLowerCase().contains(_search.toLowerCase()));
      final matchLang = _filterLang == 'all' || s.language == _filterLang;
      final matchFav = !_favOnly || s.isFavorite;
      return matchSearch && matchLang && matchFav;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('// code library',
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Snippets',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ]),
                Row(children: [
                  GestureDetector(
                    onTap: () => setState(() => _favOnly = !_favOnly),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _favOnly
                            ? (isDark ? AppTheme.white : AppTheme.black)
                            : (isDark ? AppTheme.white : AppTheme.black)
                                .withOpacity(0.07),
                        border: Border.all(
                            color: (isDark ? AppTheme.white : AppTheme.black)
                                .withOpacity(0.1)),
                      ),
                      child: Icon(
                          _favOnly ? Icons.star : Icons.star_outline,
                          size: 18,
                          color: _favOnly
                              ? (isDark ? AppTheme.black : AppTheme.white)
                              : (isDark ? AppTheme.white : AppTheme.black)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddSnippet(context, isDark),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (isDark ? AppTheme.white : AppTheme.black)
                            .withOpacity(0.07),
                        border: Border.all(
                            color: (isDark ? AppTheme.white : AppTheme.black)
                                .withOpacity(0.1)),
                      ),
                      child: Icon(Icons.add,
                          size: 20,
                          color: isDark ? AppTheme.white : AppTheme.black),
                    ),
                  ),
                ]),
              ],
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassTextField(
              hintText: 'Search snippets...',
              prefixIcon: Icon(Icons.search,
                  size: 18,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          const SizedBox(height: 10),

          // Language filter
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                'all',
                ...CodeSnippet.supportedLanguages.take(10)
              ].map((lang) {
                final selected = _filterLang == lang;
                return GestureDetector(
                  onTap: () => setState(() => _filterLang = lang),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: selected
                          ? (isDark ? AppTheme.white : AppTheme.black)
                          : (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.07),
                    ),
                    child: Text(lang,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: selected
                              ? (isDark ? AppTheme.black : AppTheme.white)
                              : (isDark ? AppTheme.silver : AppTheme.gray),
                        )),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('{ }',
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 40,
                                  color: isDark
                                      ? AppTheme.gray
                                      : AppTheme.lightGray)),
                          const SizedBox(height: 12),
                          Text('No snippets found',
                              style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? AppTheme.white : AppTheme.black)),
                        ]).animate().fadeIn(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final snippet = filtered[i];
                      return _SnippetCard(
                        snippet: snippet,
                        isDark: isDark,
                        index: i,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSnippet(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String language = 'dart';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: SingleChildScrollView(
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
                            color: (isDark ? AppTheme.white : AppTheme.black)
                                .withOpacity(0.2)))),
                const SizedBox(height: 20),
                Text('Add Snippet',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black)),
                const SizedBox(height: 16),
                GlassTextField(
                    controller: titleCtrl, hintText: 'Snippet title'),
                const SizedBox(height: 10),
                GlassTextField(
                    controller: descCtrl,
                    hintText: 'Description (optional)'),
                const SizedBox(height: 10),

                // Language selector
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: language,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 13,
                          color: isDark ? AppTheme.white : AppTheme.black),
                      items: CodeSnippet.supportedLanguages
                          .map((l) =>
                              DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setS(() => language = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GlassTextField(
                  controller: codeCtrl,
                  hintText: 'Paste your code here...',
                  maxLines: 8,
                ),
                const SizedBox(height: 10),
                GlassTextField(
                  controller: tagsCtrl,
                  hintText: 'Tags: api, helper, widget (comma separated)',
                ),
                const SizedBox(height: 16),
                GlassButton(
                  label: 'Save Snippet',
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
                    final tags = tagsCtrl.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    await ref
                        .read(snippetsControllerProvider.notifier)
                        .addSnippet(
                          title: titleCtrl.text.trim(),
                          code: codeCtrl.text.trim(),
                          language: language,
                          tags: tags,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SnippetCard extends ConsumerStatefulWidget {
  final CodeSnippet snippet;
  final bool isDark;
  final int index;

  const _SnippetCard(
      {required this.snippet, required this.isDark, required this.index});

  @override
  ConsumerState<_SnippetCard> createState() => _SnippetCardState();
}

class _SnippetCardState extends ConsumerState<_SnippetCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.snippet;
    final isDark = widget.isDark;

    return GlassCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
              ),
              child: Text(s.language,
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: isDark ? AppTheme.silver : AppTheme.gray)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(s.title,
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black))),
            IconButton(
              icon: Icon(
                  s.isFavorite ? Icons.star : Icons.star_outline,
                  size: 18,
                  color: s.isFavorite
                      ? Colors.amber
                      : (isDark ? AppTheme.gray : AppTheme.lightGray)),
              onPressed: () => ref
                  .read(snippetsControllerProvider.notifier)
                  .toggleFavorite(s),
            ),
            IconButton(
              icon: Icon(Icons.copy,
                  size: 16,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: s.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied!',
                        style: TextStyle(fontFamily: 'JetBrainsMono')),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent.withOpacity(0.8)),
              onPressed: () => _confirmDelete(context, ref, s), // هننادي ميثود التأكيد
            ),
          ]),

          if (s.description != null) ...[
            const SizedBox(height: 4),
            Text(s.description!,
                style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray)),
          ],

          if (_expanded) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HighlightView(
                s.code,
                language: s.language,
                theme: isDark ? monokaiSublimeTheme : githubTheme,
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(
                    fontFamily: 'JetBrainsMono', fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  // 1. إظهار الـ Loading Dialog
                  // بنستخدم rootNavigator: true عشان نضمن إنه يظهر فوق أي حاجة
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),
                  );
            
                  try {
                    // 2. طلب الشرح من الـ AI
                    final explanation = await ref.read(aiGenerationProvider.notifier)
                        .explainMyCode(s.code, s.language);
            
                    // 3. (أهم خطوة) التأكد إن الشاشة لسه معروضة والمستخدم مخرجش منها
                    if (!mounted) return;
            
                    // 4. قفل الـ Loading Dialog الأول قبل ما نفتح الجديد
                    Navigator.of(context, rootNavigator: true).pop();
            
                    // 5. إظهار النتيجة في AlertDialog شيك
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'AI Explanation',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView( // عشان لو الشرح طويل ميعملش Overflow
                          child: Text(
                            explanation ?? 'Sorry, I couldn\'t explain this code snippet.',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? AppTheme.lightGray : AppTheme.gray,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Close',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  } catch (e) {
                    // 6. لو حصل أي Error بنقفل الـ Loading عشان التطبيق ميهنجش
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                label: Text(
                  'Explain Code',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: isDark ? AppTheme.white : AppTheme.black,
                  ),
                ),
              ),
            )
          ] else ...[
            const SizedBox(height: 8),
            Text(
              s.code.split('\n').take(2).join('\n'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray),
            ),
            const SizedBox(height: 4),
            Text('Tap to expand',
                style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    letterSpacing: 0.5)),
          ],

          if (s.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: s.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.06),
                        ),
                        child: Text('#$t',
                            style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 9,
                                color: isDark ? AppTheme.silver : AppTheme.gray)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (widget.index * 60).ms);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CodeSnippet snippet) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: widget.isDark ? AppTheme.darkMid : AppTheme.white,
      title: const Text('Delete Snippet?', 
          style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold)),
      content: Text('Are you sure you want to delete "${snippet.title}"?',
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black54)),
        ),
        TextButton(
          onPressed: () {
            // نداء البروفايدر للمسح
            ref.read(snippetsControllerProvider.notifier).deleteSnippet(snippet.id);
            Navigator.pop(ctx);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
}