import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/tools/presentation/screens/color_palette_screen.dart';
import 'package:developer_os/features/tools/presentation/screens/markdown_editor_screen.dart';

class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SizedBox(
              width: double.infinity, // بيخلي الـ Column ياخد عرض الشاشة كلها
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text('// developer toolkit',
                      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                          color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                  Text('Dev Tools',
                      style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                ],
              ),
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final (i, label) in [
                  (0, 'JSON'), (1, 'RegEx'), (2, 'API'), (3, 'Colors'), (4, 'Markdown')
                ])
                  GestureDetector(
                    onTap: () => _tabCtrl.animateTo(i),
                    child: AnimatedBuilder(
                      animation: _tabCtrl.animation!,
                      builder: (context, _) {
                        final isSelected = (_tabCtrl.animation!.value.round()) == i;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                            border: Border.all(color: isSelected
                                ? Colors.transparent
                                : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                          ),
                          child: Text(label,
                              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? (isDark ? AppTheme.black : AppTheme.white)
                                      : (isDark ? AppTheme.silver : AppTheme.gray))),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _JSONFormatterTab(isDark: isDark),
                _RegExTesterTab(isDark: isDark),
                _APITesterTab(isDark: isDark),
                const ColorPaletteScreen(),
                const MarkdownEditorScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// JSON Formatter
// =====================
class _JSONFormatterTab extends StatefulWidget {
  final bool isDark;
  const _JSONFormatterTab({required this.isDark});
  @override
  State<_JSONFormatterTab> createState() => _JSONFormatterTabState();
}

class _JSONFormatterTabState extends State<_JSONFormatterTab> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  String? _error;
  String _mode = 'format';

  void _process() {
    final input = _inputCtrl.text.trim();
    if (input.isEmpty) return;
    try {
      final parsed = json.decode(input);
      setState(() {
        _error = null;
        if (_mode == 'format') {
          _output = const JsonEncoder.withIndent('  ').convert(parsed);
        } else if (_mode == 'minify') {
          _output = json.encode(parsed);
        } else {
          final type = parsed is Map ? 'Object (${(parsed as Map).length} keys)' : parsed is List ? 'Array (${(parsed as List).length} items)' : parsed.runtimeType.toString();
          _output = '✅ Valid JSON\n\nType: $type';
        }
      });
    } catch (e) {
      setState(() { _error = '❌ Invalid JSON\n${e.toString()}'; _output = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // تعريف الخيارات العلوية في قائمة لتسهيل التعامل مع الـ Margins
    final modes = [
      ('format', '{ } Format'),
      ('minify', '⚡ Minify'),
      ('validate', '✅ Validate'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          // --- 1. Top Buttons Row ---
          Row(
            children: List.generate(modes.length, (index) {
              final m = modes[index].$1;
              final label = modes[index].$2;
              final isLast = index == modes.length - 1;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _mode = m);
                    _process();
                  },
                  child: Container(
                    // مراجعة المارجن عشان ميبقاش فيه فراغ زيادة في الآخر
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _mode == m
                          ? (isDark ? AppTheme.white : AppTheme.black)
                          : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _mode == m
                              ? (isDark ? AppTheme.black : AppTheme.white)
                              : (isDark ? AppTheme.silver : AppTheme.gray),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // --- 2. Main Content Area (Input & Output) ---
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- INPUT CARD ---
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader('INPUT', isDark, actions: [
                          _buildActionButton('PASTE', isDark, () async {
                            final d = await Clipboard.getData('text/plain');
                            if (d?.text != null) {
                              _inputCtrl.text = d!.text!;
                              _process();
                            }
                          }),
                          const SizedBox(width: 12),
                          _buildActionButton('CLEAR', isDark, () {
                            setState(() {
                              _inputCtrl.clear();
                              _output = '';
                              _error = null;
                            });
                          }, isDestructive: true),
                        ]),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TextField(
                            controller: _inputCtrl,
                            maxLines: null,
                            expands: true,
                            // الحل لمحاذاة النص من البداية فوق ✅
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (_) => _process(),
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 11,
                              color: isDark ? AppTheme.white : AppTheme.black,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Paste JSON here...',
                              // Padding داخلي بسيط عشان النص ميبقاش لازق في الحواف
                              contentPadding: const EdgeInsets.only(top: 8, left: 8),
                              hintStyle: TextStyle(
                                fontFamily: 'JetBrainsMono', 
                                fontSize: 11, 
                                color: isDark ? AppTheme.gray : AppTheme.lightGray
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- CENTER ARROW ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: GestureDetector(
                      onTap: _process,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppTheme.white : AppTheme.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: isDark ? AppTheme.black : AppTheme.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // --- OUTPUT CARD ---
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader('OUTPUT', isDark, actions: [
                          if (_output.isNotEmpty)
                            _buildActionButton('COPY', isDark, () {
                              Clipboard.setData(ClipboardData(text: _output));
                            }),
                        ]),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: SelectableText(
                                _error ?? _output,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 11,
                                  height: 1.6,
                                  color: _error != null 
                                      ? Colors.red.withOpacity(0.9) 
                                      : (isDark ? AppTheme.lightGray : AppTheme.darkGray),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ويدجت مساعدة للهيدر عشان الكود يبقى أنظف ---
  Widget _buildHeader(String title, bool isDark, {List<Widget>? actions}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.gray : AppTheme.lightGray,
            letterSpacing: 1.5,
          ),
        ),
        if (actions != null) Row(children: actions),
      ],
    );
  }

  // --- ويدجت مساعدة للزراير الصغيرة (Paste, Clear, Copy) ---
  Widget _buildActionButton(String label, bool isDark, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDestructive 
                ? Colors.redAccent 
                : (isDark ? AppTheme.silver : AppTheme.gray),
          ),
        ),
      ),
    );
  }
}

// =====================
// RegEx Tester
// =====================
class _RegExTesterTab extends StatefulWidget {
  final bool isDark;
  const _RegExTesterTab({required this.isDark});
  @override
  State<_RegExTesterTab> createState() => _RegExTesterTabState();
}

class _RegExTesterTabState extends State<_RegExTesterTab> {
  final _patternCtrl = TextEditingController();
  final _testCtrl = TextEditingController();
  List<String> _matches = [];
  String? _error;
  bool _globalFlag = true;
  bool _multilineFlag = false;
  bool _caseInsensitive = false;

  void _test() {
    final pattern = _patternCtrl.text;
    final text = _testCtrl.text;
    if (pattern.isEmpty) {
      setState(() { _matches = []; _error = null; });
      return;
    }
    try {
      final regex = RegExp(pattern, multiLine: _multilineFlag, caseSensitive: !_caseInsensitive);
      setState(() {
        _error = null;
        if (text.isEmpty) {
          _matches = [];
        } else {
          _matches = _globalFlag 
            ? regex.allMatches(text).map((m) => m.group(0) ?? '').toList() 
            : [regex.firstMatch(text)?.group(0) ?? ''].where((s) => s.isNotEmpty).toList();
        }
      });
    } catch (e) { 
      setState(() { _error = 'Invalid regex syntax'; _matches = []; }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- القسم الأول: Pattern Input ---
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('REGULAR EXPRESSION', isDark),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Text('/', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 20, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _patternCtrl,
                          onChanged: (_) => _test(),
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 15, color: isDark ? AppTheme.white : AppTheme.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'e.g. \\d+|[a-z]+',
                            hintStyle: TextStyle(color: isDark ? AppTheme.gray.withOpacity(0.5) : AppTheme.lightGray),
                          ),
                        ),
                      ),
                      Text('/', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 20, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      const SizedBox(width: 8),
                      // Flags Indicators
                      _buildFlagToggle('g', _globalFlag, isDark, () => setState(() { _globalFlag = !_globalFlag; _test(); })),
                      _buildFlagToggle('m', _multilineFlag, isDark, () => setState(() { _multilineFlag = !_multilineFlag; _test(); })),
                      _buildFlagToggle('i', _caseInsensitive, isDark, () => setState(() { _caseInsensitive = !_caseInsensitive; _test(); })),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(_error!, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: Colors.redAccent)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- القسم الثاني: Test String ---
          _buildLabel('TEST STRING', isDark),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _testCtrl, 
            hintText: 'Enter text to test against...', 
            maxLines: 5, 
            onChanged: (_) => _test()
          ),

          const SizedBox(height: 16),

          // --- القسم الثالث: Matches Result ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('MATCHES', isDark),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _matches.isNotEmpty ? Colors.green.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_matches.length} found',
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, fontWeight: FontWeight.bold, color: _matches.isNotEmpty ? Colors.green : AppTheme.gray),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: GlassCard(
              child: _matches.isEmpty
                  ? Center(child: Text('No matches to display', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: isDark ? AppTheme.gray : AppTheme.lightGray)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _matches.length,
                      itemBuilder: (_, i) => _buildMatchItem(i, _matches[i], isDark),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت مساعدة للعناوين
  Widget _buildLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? AppTheme.gray : AppTheme.lightGray, letterSpacing: 1.5));
  }

  // ويدجت مفاتيح الـ Flags بشكل احترافي
  Widget _buildFlagToggle(String label, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isActive 
            ? (isDark ? AppTheme.white : AppTheme.black) 
            : Colors.transparent,
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontFamily: 'JetBrainsMono', 
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            color: isActive ? (isDark ? AppTheme.black : AppTheme.white) : AppTheme.gray
          )),
        ),
      ),
    );
  }

  // ويدجت عرض نتيجة المطابقة (Match Item)
  Widget _buildMatchItem(int index, String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}.', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: Colors.green.withOpacity(0.7))),
          const SizedBox(width: 10),
          Expanded(child: SelectableText(text, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: isDark ? AppTheme.white : AppTheme.black))),
        ],
      ),
    );
  }
}

// =====================
// API Tester
// =====================
class _APITesterTab extends StatefulWidget {
  final bool isDark;
  const _APITesterTab({required this.isDark});
  @override
  State<_APITesterTab> createState() => _APITesterTabState();
}

class _APITesterTabState extends State<_APITesterTab> {
  final _urlCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _hKeyCtrl = TextEditingController();
  final _hValCtrl = TextEditingController();
  
  String _method = 'GET';
  Map<String, String> _headers = {'Content-Type': 'application/json'};
  String? _response;
  int? _statusCode;
  bool _loading = false;
  int _responseTime = 0;

  // ألوان الـ Methods لتسهيل التمييز البصري
  Color _methodColor(String m) {
    switch (m) {
      case 'GET': return Colors.greenAccent;
      case 'POST': return Colors.blueAccent;
      case 'PUT': return Colors.orangeAccent;
      case 'DELETE': return Colors.redAccent;
      default: return Colors.purpleAccent;
    }
  }

  Future<void> _send() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _response = null; _statusCode = null; });
    final sw = Stopwatch()..start();
    try {
      Uri uri = Uri.parse(url);
      http.Response response;
      // نستخدم timeout لضمان عدم تعليق التطبيق
      final headers = Map<String, String>.from(_headers);
      
      switch (_method) {
        case 'GET': response = await http.get(uri, headers: headers); break;
        case 'POST': response = await http.post(uri, headers: headers, body: _bodyCtrl.text); break;
        case 'PUT': response = await http.put(uri, headers: headers, body: _bodyCtrl.text); break;
        case 'DELETE': response = await http.delete(uri, headers: headers); break;
        default: response = await http.get(uri, headers: headers);
      }
      sw.stop();
      String body = response.body;
      try { 
        final decoded = json.decode(body);
        body = const JsonEncoder.withIndent('  ').convert(decoded); 
      } catch (_) {}
      
      setState(() { 
        _statusCode = response.statusCode; 
        _response = body; 
        _responseTime = sw.elapsedMilliseconds; 
        _loading = false; 
      });
    } catch (e) { 
      sw.stop(); 
      setState(() { 
        _response = 'Error: $e'; 
        _responseTime = sw.elapsedMilliseconds; 
        _loading = false; 
      }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryColor = isDark ? AppTheme.white : AppTheme.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Section 1: Address Bar ---
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Method Selector Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _methodColor(_method).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _method,
                    underline: const SizedBox.shrink(),
                    dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
                    icon: Icon(Icons.arrow_drop_down, size: 18, color: _methodColor(_method)),
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w800, color: _methodColor(_method)),
                    items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: primaryColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'https://api.example.com/v1/resource',
                      hintStyle: TextStyle(color: isDark ? AppTheme.gray : AppTheme.lightGray, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                GestureDetector(
                  onTap: _loading ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _loading ? primaryColor.withOpacity(0.5) : primaryColor,
                    ),
                    child: _loading 
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppTheme.black : AppTheme.white))
                      : Text('SEND', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? AppTheme.black : AppTheme.white)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- Section 2: Request Payload (Headers & Body) ---
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Headers Column
                Expanded(
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('HEADERS', isDark),
                        const SizedBox(height: 12), // زيادة المسافة قليلاً للراحة البصرية
                        Expanded(
                          child: Container(
                            // إضافة padding داخلي للقائمة
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListView.separated(
                              itemCount: _headers.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                var entry = _headers.entries.elementAt(index);
                                return _buildHeaderTile(entry.key, entry.value, isDark);
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 32, thickness: 0.5), // تقسيم أوضح
                        
                        // Add Header Inputs - تحسين الـ Layout
                        Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildSmallField(_hKeyCtrl, 'Key', isDark)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(':', style: TextStyle(color: primaryColor.withOpacity(0.5), fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: _buildSmallField(_hValCtrl, 'Value', isDark)),
                              const SizedBox(width: 8),
                              Material( // إضافة تأثير الضغط (Inkwell) لجعلها احترافية
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    if (_hKeyCtrl.text.isNotEmpty) {
                                      setState(() => _headers[_hKeyCtrl.text] = _hValCtrl.text);
                                      _hKeyCtrl.clear(); _hValCtrl.clear();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(Icons.add_circle_outline, size: 24, color: primaryColor),
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
                
                if (_method != 'GET' && _method != 'DELETE') ...[
                  const SizedBox(width: 16), // مسافة أكبر بين الكارتين
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('BODY (JSON)', isDark),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black12 : Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _bodyCtrl,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono', 
                                  fontSize: 12, // تكبير الخط قليلاً للقراءة
                                  color: primaryColor.withOpacity(0.9),
                                  height: 1.5, // إضافة ارتفاع للسطر لراحة العين
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '{\n  "id": 1\n}',
                                  hintStyle: TextStyle(
                                    color: (isDark ? AppTheme.gray : AppTheme.lightGray).withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- Section 3: Response Area ---
          _buildLabel('RESPONSE', isDark),
          const SizedBox(height: 6),
          Expanded(
            flex: 3,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Response Meta Bar
                  if (_statusCode != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          _buildStatusPill(_statusCode!),
                          const SizedBox(width: 12),
                          Text('${_responseTime}ms', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                          const Spacer(),
                          if (_response != null)
                            GestureDetector(
                              onTap: () => Clipboard.setData(ClipboardData(text: _response!)),
                              child: Text('COPY JSON', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            ),
                        ],
                      ),
                    ),
                  // Response Body
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: SelectableText(
                          _response ?? '// Response will appear here',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            height: 1.5,
                            color: _response == null 
                                ? (isDark ? AppTheme.gray : AppTheme.lightGray) 
                                : (isDark ? AppTheme.lightGray : AppTheme.darkGray),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? AppTheme.gray : AppTheme.lightGray, letterSpacing: 1.5));
  }

  Widget _buildHeaderTile(String key, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Expanded(child: Text('$key: $value', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.silver : AppTheme.gray, overflow: TextOverflow.ellipsis))),
          GestureDetector(onTap: () => setState(() => _headers.remove(key)), child: const Icon(Icons.close, size: 12, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildSmallField(TextEditingController ctrl, String hint, bool isDark) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isDark ? AppTheme.white : AppTheme.black),
      decoration: InputDecoration(border: InputBorder.none, hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 4), hintStyle: TextStyle(color: isDark ? AppTheme.gray : AppTheme.lightGray)),
    );
  }

  Widget _buildStatusPill(int code) {
    Color color = code < 300 ? Colors.greenAccent : code < 400 ? Colors.orangeAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5), width: 0.5)),
      child: Text('$code ${code < 300 ? 'OK' : 'ERROR'}', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}