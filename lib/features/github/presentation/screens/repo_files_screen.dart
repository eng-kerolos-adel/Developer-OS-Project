import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/github/providers/github_provider.dart';
import 'package:developer_os/features/github/domain/models/github_models.dart';

class RepoFilesScreen extends ConsumerStatefulWidget {
  final String repoName;
  final String projectName;
  final String? githubUrl;

  const RepoFilesScreen({
    super.key,
    required this.repoName,
    required this.projectName,
    this.githubUrl,
  });

  @override
  ConsumerState<RepoFilesScreen> createState() => _RepoFilesScreenState();
}

class _RepoFilesScreenState extends ConsumerState<RepoFilesScreen> {
  final List<String> _pathStack = ['']; // stack للـ navigation
  String? _viewingFile; // اسم الملف اللي شايفه
  String? _viewingFilePath;

  String get _currentPath => _pathStack.last;

  String get _breadcrumb {
    if (_pathStack.length == 1) return widget.repoName;
    return '${widget.repoName}/${_pathStack.skip(1).join('/')}';
  }

  void _openDir(String path) {
    setState(() {
      _pathStack.add(path);
      _viewingFile = null;
      _viewingFilePath = null;
    });
  }

  void _goBack() {
    if (_viewingFile != null) {
      setState(() {
        _viewingFile = null;
        _viewingFilePath = null;
      });
      return;
    }
    if (_pathStack.length > 1) {
      setState(() => _pathStack.removeLast());
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: _goBack,
                  child: Icon(Icons.arrow_back_ios,
                      color: isDark ? AppTheme.white : AppTheme.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('// repository files',
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    Text(
                      _viewingFile ?? _breadcrumb,
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                if (widget.githubUrl != null)
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(widget.githubUrl!),
                        mode: LaunchMode.externalApplication),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                        border: Border.all(
                            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                      ),
                      child: Row(children: [
                        Icon(Icons.open_in_new, size: 13,
                            color: isDark ? AppTheme.silver : AppTheme.gray),
                        const SizedBox(width: 4),
                        Text('GitHub', style: TextStyle(fontFamily: 'JetBrainsMono',
                            fontSize: 11, color: isDark ? AppTheme.silver : AppTheme.gray)),
                      ]),
                    ),
                  ),
              ]).animate().fadeIn(),
            ),

            const SizedBox(height: 8),

            // Breadcrumb path
            if (_pathStack.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _pathStack.clear();
                            _pathStack.add('');
                            _viewingFile = null;
                          }),
                          child: Text(widget.repoName,
                              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                  color: isDark ? AppTheme.silver : AppTheme.gray)),
                        ),
                        ..._pathStack.skip(1).toList().asMap().entries.map((entry) {
                          final i = entry.key;
                          final segment = entry.value.split('/').last;
                          return Row(children: [
                            Text(' / ', style: TextStyle(
                                fontFamily: 'JetBrainsMono', fontSize: 11,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                            GestureDetector(
                              onTap: () => setState(() {
                                _pathStack.removeRange(i + 2, _pathStack.length);
                                _viewingFile = null;
                              }),
                              child: Text(segment,
                                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                      color: isDark ? AppTheme.white : AppTheme.black,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]);
                        }),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: _viewingFile != null && _viewingFilePath != null
                  ? _FileViewerPane(
                      repoName: widget.repoName,
                      filePath: _viewingFilePath!,
                      fileName: _viewingFile!,
                      isDark: isDark,
                    )
                  : _FilesListPane(
                      repoName: widget.repoName,
                      currentPath: _currentPath,
                      isDark: isDark,
                      onOpenDir: _openDir,
                      onOpenFile: (file) {
                        setState(() {
                          _viewingFile = file.name;
                          _viewingFilePath = file.path;
                        });
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// Files List
// =====================
class _FilesListPane extends ConsumerWidget {
  final String repoName;
  final String currentPath;
  final bool isDark;
  final void Function(String path) onOpenDir;
  final void Function(GitHubFile file) onOpenFile;

  const _FilesListPane({
    required this.repoName,
    required this.currentPath,
    required this.isDark,
    required this.onOpenDir,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = RepoFilesParams(repoName: repoName, path: currentPath);
    final filesAsync = ref.watch(repoFilesProvider(params));

    return filesAsync.when(
      loading: () => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(
              color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2),
          const SizedBox(height: 12),
          Text('Loading files...',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ]),
      ),
      error: (e, _) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 40,
              color: isDark ? AppTheme.gray : AppTheme.lightGray),
          const SizedBox(height: 12),
          Text('Could not load files', style: TextStyle(fontFamily: 'JetBrainsMono',
              fontSize: 14, color: isDark ? AppTheme.white : AppTheme.black)),
          const SizedBox(height: 6),
          Text('Check GitHub connection', style: TextStyle(fontFamily: 'JetBrainsMono',
              fontSize: 11, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ]),
      ),
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Text('Empty directory',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray)),
          );
        }

        // مجلدات الأول ثم ملفات
        final sorted = [...files]
          ..sort((a, b) {
            if (a.isDirectory && b.isFile) return -1;
            if (a.isFile && b.isDirectory) return 1;
            return a.name.compareTo(b.name);
          });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06),
          ),
          itemBuilder: (context, i) {
            final file = sorted[i];
            return InkWell(
              onTap: () {
                if (file.isDirectory) {
                  onOpenDir(file.path);
                } else {
                  onOpenFile(file);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(children: [
                  Text(file.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(file.name,
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                              fontWeight: file.isDirectory ? FontWeight.w700 : FontWeight.w400,
                              color: isDark ? AppTheme.white : AppTheme.black)),
                      if (file.isFile && file.size != null)
                        Text(file.formattedSize,
                            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                                color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                    ]),
                  ),
                  Icon(
                    file.isDirectory ? Icons.chevron_right : Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray,
                  ),
                ]),
              ),
            ).animate().fadeIn(delay: (i * 30).ms);
          },
        );
      },
    );
  }
}

// =====================
// File Viewer
// =====================
class _FileViewerPane extends ConsumerWidget {
  final String repoName;
  final String filePath;
  final String fileName;
  final bool isDark;

  const _FileViewerPane({
    required this.repoName,
    required this.filePath,
    required this.fileName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = FileContentParams(repoName: repoName, filePath: filePath);
    final contentAsync = ref.watch(fileContentProvider(params));

    return contentAsync.when(
      loading: () => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(
              color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2),
          const SizedBox(height: 12),
          Text('Loading $fileName...',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        ]),
      ),
      error: (e, _) => Center(
        child: Text('Cannot load file content',
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                color: isDark ? AppTheme.gray : AppTheme.lightGray)),
      ),
      data: (content) {
        if (content == null) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🖼️', style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Binary file — cannot preview',
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            ]),
          );
        }

        return Column(
          children: [
            // Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(children: [
                Expanded(
                  child: Text('$fileName',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                          color: isDark ? AppTheme.silver : AppTheme.gray),
                      overflow: TextOverflow.ellipsis),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard!',
                            style: TextStyle(fontFamily: 'JetBrainsMono')),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                    ),
                    child: Row(children: [
                      Icon(Icons.copy, size: 13,
                          color: isDark ? AppTheme.silver : AppTheme.gray),
                      const SizedBox(width: 4),
                      Text('Copy', style: TextStyle(fontFamily: 'JetBrainsMono',
                          fontSize: 11, color: isDark ? AppTheme.silver : AppTheme.gray)),
                    ]),
                  ),
                ),
              ]),
            ),

            // File content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      content,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        height: 1.6,
                        color: isDark ? AppTheme.lightGray : AppTheme.darkGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}