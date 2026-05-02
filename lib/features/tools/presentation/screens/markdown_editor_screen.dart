import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';

class MarkdownDocument {
  final String id, uid, title, content;
  final DateTime createdAt, updatedAt;
  const MarkdownDocument({required this.id, required this.uid, required this.title, required this.content, required this.createdAt, required this.updatedAt});
  int get wordCount => content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
  int get lineCount => content.split('\n').length;
  int get charCount => content.length;
  factory MarkdownDocument.fromMap(Map<String, dynamic> m, String id) => MarkdownDocument(id: id, uid: m['uid'] ?? '', title: m['title'] ?? 'Untitled', content: m['content'] ?? '', createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] ?? 0), updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] ?? 0));
  Map<String, dynamic> toMap() => {'uid': uid, 'title': title, 'content': content, 'createdAt': createdAt.millisecondsSinceEpoch, 'updatedAt': DateTime.now().millisecondsSinceEpoch};
}

final markdownDocsProvider = StreamProvider<List<MarkdownDocument>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance.collection('users').doc(uid).collection('markdown_docs').orderBy('updatedAt', descending: true).snapshots().map((s) => s.docs.map((d) => MarkdownDocument.fromMap(d.data(), d.id)).toList());
});

final markdownControllerProvider = StateNotifierProvider<MarkdownController, AsyncValue<void>>((ref) => MarkdownController(ref));

class MarkdownController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MarkdownController(this._ref) : super(const AsyncValue.data(null));
  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';
  CollectionReference get _col => FirebaseFirestore.instance.collection('users').doc(_uid).collection('markdown_docs');
  Future<String> saveDoc(String id, String title, String content) async {
    final docId = id.isEmpty ? const Uuid().v4() : id;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _col.doc(docId).set({'uid': _uid, 'title': title.trim().isEmpty ? 'Untitled' : title.trim(), 'content': content, 'createdAt': now, 'updatedAt': now}, SetOptions(merge: true));
    return docId;
  }
  Future<void> deleteDoc(String id) async => _col.doc(id).delete();
}

class _ToolbarItem {
  final String label, prefix;
  final String? suffix;
  const _ToolbarItem(this.label, this.prefix, [this.suffix]);
}

const _toolbar = [
  _ToolbarItem('B', '**', '**'),
  _ToolbarItem('I', '*', '*'),
  _ToolbarItem('`', '`', '`'),
  _ToolbarItem('H1', '# '),
  _ToolbarItem('H2', '## '),
  _ToolbarItem('H3', '### '),
  _ToolbarItem('—', '\n---\n'),
  _ToolbarItem('•', '- '),
  _ToolbarItem('1.', '1. '),
  _ToolbarItem('> ', '> '),
  _ToolbarItem('[ ]', '[', '](url)'),
  _ToolbarItem('```', '```\n', '\n```'),
];

// ── Documents List Screen ────────────────────────────────────────────
class MarkdownEditorScreen extends ConsumerWidget {
  const MarkdownEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docsAsync = ref.watch(markdownDocsProvider);

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('// documentation', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
              Text('Markdown', style: TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)),
            ]),
            GestureDetector(
              onTap: () => _push(context, null),
              child: Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? AppTheme.white : AppTheme.black), child: Icon(Icons.add, size: 22, color: isDark ? AppTheme.black : AppTheme.white)),
            ),
          ]).animate().fadeIn(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: docsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (docs) {
              if (docs.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📝', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 20),
                  Text('No documents yet', style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)),
                  const SizedBox(height: 8),
                  Text('// write docs, notes, READMEs', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  const SizedBox(height: 32),
                  GlassButton(label: '+ New Document', width: 200, onPressed: () => _push(context, null)),
                ]).animate().fadeIn());
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final preview = doc.content.replaceAll(RegExp(r'#+\s'), '').replaceAll(RegExp(r'\*+'), '').replaceAll('`', '').trim();
                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref.read(markdownControllerProvider.notifier).deleteDoc(doc.id),
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.red.withOpacity(0.1)), child: const Icon(Icons.delete_outline, color: Colors.red, size: 22)),
                    child: GlassCard(
                      onTap: () => _push(context, doc),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(doc.title, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black))),
                          GestureDetector(
                            onTap: () { Clipboard.setData(ClipboardData(text: doc.content)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Copied!', style: TextStyle(fontFamily: 'JetBrainsMono')), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); },
                            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)), child: Icon(Icons.copy, size: 14, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? AppTheme.gray : AppTheme.lightGray),
                        ]),
                        if (preview.isNotEmpty) ...[const SizedBox(height: 6), Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, height: 1.5, color: isDark ? AppTheme.gray : AppTheme.lightGray))],
                        const SizedBox(height: 10),
                        Row(children: [
                          _chip('${doc.wordCount}w', isDark), const SizedBox(width: 8), _chip('${doc.lineCount}L', isDark),
                          const Spacer(),
                          Text(DateFormat('dd MMM yyyy').format(doc.updatedAt), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                        ]),
                      ]),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 50)),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)),
    child: Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
  );

  void _push(BuildContext context, MarkdownDocument? doc) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, anim, _) => _EditorPage(doc: doc),
      transitionsBuilder: (context, anim, _, child) => SlideTransition(position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
    ));
  }
}

// ── Full-Screen Editor ────────────────────────────────────────────────
class _EditorPage extends ConsumerStatefulWidget {
  final MarkdownDocument? doc;
  const _EditorPage({this.doc});
  @override
  ConsumerState<_EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<_EditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _contentFocus = FocusNode();
  bool _preview = false, _saving = false, _dirty = false;
  String? _docId;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      _docId = widget.doc!.id;
      _titleCtrl.text = widget.doc!.title;
      _contentCtrl.text = widget.doc!.content;
    }
    _titleCtrl.addListener(_onChange);
    _contentCtrl.addListener(_onChange);
  }

  void _onChange() {
    if (!_dirty) setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => _save(silent: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.removeListener(_onChange);
    _contentCtrl.removeListener(_onChange);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _save({bool silent = false}) async {
    if (!mounted) return;
    setState(() => _saving = true);
    final id = await ref.read(markdownControllerProvider.notifier).saveDoc(_docId ?? '', _titleCtrl.text, _contentCtrl.text);
    _docId = id;
    if (mounted) setState(() { _saving = false; _dirty = false; });
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Saved', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12)),
        duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _insert(_ToolbarItem item) {
    final ctrl = _contentCtrl;
    final sel = ctrl.selection;
    final txt = ctrl.text;
    final selected = sel.isValid && !sel.isCollapsed ? txt.substring(sel.start, sel.end) : '';
    final insert = item.suffix != null ? '${item.prefix}${selected.isNotEmpty ? selected : ''}${item.suffix}' : item.prefix;
    final before = sel.isValid ? txt.substring(0, sel.start) : txt;
    final after = sel.isValid ? txt.substring(sel.end) : '';
    ctrl.value = TextEditingValue(text: before + insert + after, selection: TextSelection.collapsed(offset: before.length + insert.length));
    _contentFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final words = _contentCtrl.text.trim().isEmpty ? 0 : _contentCtrl.text.trim().split(RegExp(r'\s+')).length;
    final chars = _contentCtrl.text.length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkest : AppTheme.offWhite,
      // KEY: resizeToAvoidBottomInset=true means Flutter shrinks the body
      // when keyboard appears, so the toolbar stays above the keyboard
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [

          // ─── Top Bar ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              // Back
              GestureDetector(
                onTap: () async { if (_dirty) await _save(silent: true); if (context.mounted) Navigator.pop(context); },
                child: Container(width: 36, height: 36, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)), child: Icon(Icons.arrow_back_ios, size: 15, color: isDark ? AppTheme.white : AppTheme.black)),
              ),
              const SizedBox(width: 10),
              // Doc title preview
              Expanded(child: Text(_titleCtrl.text.isEmpty ? 'New Document' : _titleCtrl.text, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: isDark ? AppTheme.silver : AppTheme.gray), overflow: TextOverflow.ellipsis)),
              // Autosave indicator
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _saving
                  ? SizedBox(key: const ValueKey('s'), width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.gray : AppTheme.lightGray))
                  : _dirty
                  ? Container(key: const ValueKey('d'), width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.orange))
                  : Container(key: const ValueKey('ok'), width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.7)))),
              const SizedBox(width: 12),
              // Preview toggle
              GestureDetector(
                onTap: () => setState(() => _preview = !_preview),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _preview ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_preview ? Icons.edit_outlined : Icons.visibility_outlined, size: 13, color: _preview ? (isDark ? AppTheme.black : AppTheme.white) : (isDark ? AppTheme.silver : AppTheme.gray)),
                    const SizedBox(width: 5),
                    Text(_preview ? 'Edit' : 'Preview', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: _preview ? (isDark ? AppTheme.black : AppTheme.white) : (isDark ? AppTheme.silver : AppTheme.gray))),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              // Save
              GestureDetector(
                onTap: () => _save(),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.green.withOpacity(0.15), border: Border.all(color: Colors.green.withOpacity(0.3))), child: const Text('Save', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green))),
              ),
            ]),
          ),

          // ─── Title ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _contentFocus.requestFocus(),
              style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black),
              decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Document title...', hintStyle: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppTheme.silver : AppTheme.gray)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(height: 1, color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08)),
          ),

          // ─── Editor / Preview (Expanded) ───────────────────
          // This is the KEY: Expanded here means it takes remaining space
          // When keyboard appears, this shrinks — which is what we want
          Expanded(
            child: _preview
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _MarkdownRenderer(content: _contentCtrl.text, isDark: isDark),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                    child: TextField(
                      controller: _contentCtrl,
                      focusNode: _contentFocus,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, height: 1.7, color: isDark ? AppTheme.offWhite : AppTheme.darkGray),
                      decoration: InputDecoration(
                        border: InputBorder.none, isCollapsed: true,
                        hintText: '# Start writing...\n\nUse the toolbar below\n**bold**, *italic*, `code`',
                        hintStyle: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, height: 1.7, color: isDark ? AppTheme.silver : AppTheme.gray),
                      ),
                    ),
                  ),
          ),

          // ─── Formatting Toolbar ─────────────────────────────
          // This sits BELOW the expanded editor and ABOVE the keyboard
          // Because Column stacks from top → the toolbar is last, it stays at bottom
          // When keyboard appears, Flutter pushes the whole SafeArea up
          // so toolbar stays just above keyboard — perfect UX!
          if (!_preview)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dark.withOpacity(0.98) : AppTheme.white.withOpacity(0.98),
                border: Border(top: BorderSide(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08))),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 46,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: _toolbar.length,
                    itemBuilder: (_, i) {
                      final item = _toolbar[i];
                      return GestureDetector(
                        onTap: () => _insert(item),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07), border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.12))),
                          child: Center(child: Text(item.label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppTheme.silver : AppTheme.gray))),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Row(children: [
                    Text('$words words', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    const SizedBox(width: 12),
                    Text('$chars chars', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ── Markdown Renderer ─────────────────────────────────────────────────
class _MarkdownRenderer extends StatelessWidget {
  final String content;
  final bool isDark;
  const _MarkdownRenderer({required this.content, required this.isDark});

  TextStyle get base => TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, height: 1.7, color: isDark ? AppTheme.offWhite : AppTheme.darkGray);

  Widget _inline(String text) {
    final spans = <TextSpan>[];
    final pat = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    int last = 0;
    for (final m in pat.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      if (m.group(1) != null) spans.add(TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.w800)));
      else if (m.group(2) != null) spans.add(TextSpan(text: m.group(2), style: base.copyWith(fontStyle: FontStyle.italic)));
      else if (m.group(3) != null) spans.add(TextSpan(text: m.group(3), style: base.copyWith(backgroundColor: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1), color: isDark ? Colors.lightGreenAccent : Colors.purple.shade700)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: base));
    return spans.isEmpty ? Text(text, style: base) : RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    bool inCode = false;
    final codeLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('```')) {
        if (!inCode) { inCode = true; codeLines.clear(); }
        else {
          inCode = false;
          widgets.add(Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: isDark ? AppTheme.black.withOpacity(0.6) : AppTheme.darkGray.withOpacity(0.05), border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1))), child: SelectableText(codeLines.join('\n'), style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, height: 1.6, color: isDark ? Colors.lightGreenAccent.withOpacity(0.9) : Colors.purple.shade700))));
          codeLines.clear();
        }
        continue;
      }
      if (inCode) { codeLines.add(line); continue; }

      if (line.startsWith('# ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(line.substring(2), style: TextStyle(fontFamily: 'Syne', fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AppTheme.white : AppTheme.black)), const SizedBox(height: 6), Container(height: 3, width: 40, decoration: BoxDecoration(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.3), borderRadius: BorderRadius.circular(2)))])));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(line.substring(3), style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black))));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(line.substring(4), style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppTheme.white : AppTheme.black))));
      } else if (line.startsWith('> ')) {
        widgets.add(Container(margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)), border: Border(left: BorderSide(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.4), width: 4)), color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.04)), child: Text(line.substring(2), style: base.copyWith(fontStyle: FontStyle.italic, color: isDark ? AppTheme.silver : AppTheme.gray))));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(left: 4, bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 9, right: 10), child: Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.5)))), Expanded(child: _inline(line.substring(2)))])));
      } else if (line.trim() == '---') {
        widgets.add(Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.15), thickness: 1)));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 2), child: _inline(line)));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}