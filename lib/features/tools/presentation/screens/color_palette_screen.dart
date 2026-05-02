import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';

// =====================
// Model
// =====================
class ColorPalette {
  final String id;
  final String uid;
  final String name;
  final List<String> colors; // hex colors
  final String? projectId;
  final DateTime createdAt;

  const ColorPalette({
    required this.id,
    required this.uid,
    required this.name,
    required this.colors,
    this.projectId,
    required this.createdAt,
  });

  factory ColorPalette.fromMap(Map<String, dynamic> m, String id) =>
      ColorPalette(
        id: id, uid: m['uid'] ?? '', name: m['name'] ?? '',
        colors: List<String>.from(m['colors'] ?? []),
        projectId: m['projectId'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] ?? 0),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid, 'name': name, 'colors': colors,
        'projectId': projectId,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  // Export formats
  String toFlutterCode() {
    final buffer = StringBuffer('// $name\n');
    for (int i = 0; i < colors.length; i++) {
      final hex = colors[i].replaceAll('#', '');
      buffer.writeln('final color$i = const Color(0xFF$hex);');
    }
    return buffer.toString();
  }

  String toCSSVariables() {
    final buffer = StringBuffer(':root {\n');
    for (int i = 0; i < colors.length; i++) {
      buffer.writeln('  --color-${i + 1}: ${colors[i]};');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String toTailwindConfig() {
    final buffer = StringBuffer('// tailwind.config.js\ncolors: {\n');
    for (int i = 0; i < colors.length; i++) {
      buffer.writeln('  "${name.toLowerCase()}-${i + 1}": "${colors[i]}",');
    }
    buffer.write('}');
    return buffer.toString();
  }
}

// =====================
// Provider
// =====================
final colorPalettesProvider = StreamProvider<List<ColorPalette>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('color_palettes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ColorPalette.fromMap(d.data(), d.id)).toList());
});

final colorPaletteControllerProvider =
    StateNotifierProvider<ColorPaletteController, AsyncValue<void>>((ref) {
  return ColorPaletteController(ref);
});

class ColorPaletteController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ColorPaletteController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  CollectionReference get _col => FirebaseFirestore.instance
      .collection('users').doc(_uid).collection('color_palettes');

  Future<void> savePalette(ColorPalette palette) async {
    await _col.doc(palette.id).set(palette.toMap());
  }

  Future<void> deletePalette(String id) async {
    await _col.doc(id).delete();
  }
}

// =====================
// Screen
// =====================
class ColorPaletteScreen extends ConsumerStatefulWidget {
  const ColorPaletteScreen({super.key});

  @override
  ConsumerState<ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends ConsumerState<ColorPaletteScreen> {
  // Built-in palettes
  static const _presetPalettes = [
    ('Monochrome', ['#000000', '#222222', '#444444', '#888888', '#BBBBBB', '#FFFFFF']),
    ('Ocean', ['#0D1B2A', '#1B4965', '#5FA8D3', '#62B4C8', '#CAE9FF', '#FFFFFF']),
    ('Forest', ['#1A2E1A', '#2D5A2D', '#4A7C59', '#74B49B', '#A7C4BC', '#F0F7EE']),
    ('Sunset', ['#1A0A00', '#6D2B0F', '#C44C1E', '#F0845E', '#FFB59A', '#FFF0E8']),
    ('Purple Haze', ['#0D0221', '#190D37', '#3D1560', '#8A2BE2', '#C77DFF', '#E8DAFF']),
    ('Minimal Blue', ['#0A0A2E', '#1B1B6B', '#2828CC', '#5050FF', '#9999FF', '#E6E6FF']),
    ('Neon', ['#000000', '#0D0D0D', '#1A1A2E', '#16213E', '#0F3460', '#E94560']),
    ('Earth', ['#3D2B1F', '#6B4226', '#A0522D', '#CD853F', '#DEB887', '#F5DEB3']),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palettesAsync = ref.watch(colorPalettesProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('// color system',
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                Text('Color Palettes',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.white : AppTheme.black)),
              ]),
              GestureDetector(
                onTap: () => _showCreatePalette(context, isDark),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                    border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                  ),
                  child: Icon(Icons.add, size: 20, color: isDark ? AppTheme.white : AppTheme.black),
                ),
              ),
            ]).animate().fadeIn(),
          ),

          const SizedBox(height: 20),

          // Preset Palettes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Preset Palettes', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.white : AppTheme.black)),
              Text('tap to save', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            ]),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _presetPalettes.length,
              itemBuilder: (context, i) {
                final preset = _presetPalettes[i];
                return GestureDetector(
                  onTap: () => _savePreset(preset.$1, preset.$2),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
                    ),
                    child: Column(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          child: Row(
                            children: preset.$2.map((hex) => Expanded(
                              child: Container(color: _hexToColor(hex)),
                            )).toList(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(preset.$1, style: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 9,
                            color: isDark ? AppTheme.silver : AppTheme.gray),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Saved Palettes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Your Palettes', style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.white : AppTheme.black)),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: palettesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(
                  color: isDark ? AppTheme.white : AppTheme.black, strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (palettes) {
                if (palettes.isEmpty) {
                  return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎨', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('No palettes saved yet', style: TextStyle(
                            fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                        const SizedBox(height: 6),
                        Text('// tap a preset or create your own', style: TextStyle(
                            fontFamily: 'JetBrainsMono', fontSize: 12,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray)),
                      ]).animate().fadeIn());
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: palettes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final palette = palettes[i];
                    return _PaletteCard(
                        palette: palette, isDark: isDark, index: i);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _savePreset(String name, List<String> colors) async {
    final uid = ref.read(currentUserProvider)?.uid ?? '';
    final palette = ColorPalette(
      id: const Uuid().v4(), uid: uid, name: name,
      colors: colors, createdAt: DateTime.now(),
    );
    await ref.read(colorPaletteControllerProvider.notifier).savePalette(palette);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name saved!',
            style: const TextStyle(fontFamily: 'JetBrainsMono')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showCreatePalette(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final colors = <Color>[Colors.black, Colors.grey, Colors.white];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          blur: 20,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)))),
            const SizedBox(height: 20),
            Text('Create Palette', style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                fontWeight: FontWeight.w700, color: isDark ? AppTheme.white : AppTheme.black)),
            const SizedBox(height: 16),
            GlassTextField(controller: nameCtrl, hintText: 'Palette name'),
            const SizedBox(height: 16),
            // Color swatches
            SizedBox(
              height: 56,
              child: Row(children: [
                ...colors.asMap().entries.map((e) => GestureDetector(
                  onTap: () => _pickColor(ctx, e.key, colors, setS, isDark),
                  child: Container(
                    width: 48, height: 48, margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: e.value,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2)),
                    ),
                  ),
                )),
                if (colors.length < 8)
                  GestureDetector(
                    onTap: () => setS(() => colors.add(Colors.blue)),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.2),
                            style: BorderStyle.solid),
                      ),
                      child: Icon(Icons.add, color: isDark ? AppTheme.gray : AppTheme.lightGray),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Save Palette',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final uid = ref.read(currentUserProvider)?.uid ?? '';
                final palette = ColorPalette(
                  id: const Uuid().v4(), uid: uid,
                  name: nameCtrl.text.trim(),
                  colors: colors.map((c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}').toList(),
                  createdAt: DateTime.now(),
                );
                await ref.read(colorPaletteControllerProvider.notifier).savePalette(palette);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ]),
        );
      }),
    );
  }

  void _pickColor(BuildContext context, int index, List<Color> colors,
      StateSetter setS, bool isDark) {
    final hexCtrl = TextEditingController(
        text: '#${colors[index].value.toRadixString(16).substring(2).toUpperCase()}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
        title: Text('Edit Color', style: TextStyle(fontFamily: 'Syne',
            color: isDark ? AppTheme.white : AppTheme.black)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(height: 60,
              decoration: BoxDecoration(color: colors[index], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 12),
          GlassTextField(controller: hexCtrl, hintText: '#RRGGBB'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final hex = hexCtrl.text.replaceAll('#', '');
              if (hex.length == 6) {
                final color = Color(int.parse('FF$hex', radix: 16));
                setS(() => colors[index] = color);
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  }
}

// =====================
// Palette Card
// =====================
class _PaletteCard extends ConsumerWidget {
  final ColorPalette palette;
  final bool isDark;
  final int index;

  const _PaletteCard({required this.palette, required this.isDark, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(palette.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(colorPaletteControllerProvider.notifier).deletePalette(palette.id),
      background: Container(alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete_outline, color: Colors.red)),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(palette.name, style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.white : AppTheme.black)),
            Row(children: [
              // Export Flutter
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: palette.toFlutterCode()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Flutter code copied!',
                        style: TextStyle(fontFamily: 'JetBrainsMono')),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                  ),
                  child: Text('Flutter', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                      color: isDark ? AppTheme.silver : AppTheme.gray)),
                ),
              ),
              const SizedBox(width: 6),
              // Export CSS
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: palette.toCSSVariables()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('CSS copied!',
                        style: TextStyle(fontFamily: 'JetBrainsMono')),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
                  ),
                  child: Text('CSS', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9,
                      color: isDark ? AppTheme.silver : AppTheme.gray)),
                ),
              ),
            ]),
          ]),

          const SizedBox(height: 12),

          // Color swatches
          Row(children: palette.colors.map((hex) {
            Color color;
            try {
              color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
            } catch (_) {
              color = Colors.grey;
            }
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: hex));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$hex copied!',
                        style: const TextStyle(fontFamily: 'JetBrainsMono')),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
                child: Tooltip(
                  message: hex,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin: const EdgeInsets.only(right: 4),
                  ),
                ),
              ),
            );
          }).toList()),

          const SizedBox(height: 8),

          // Hex values
          Row(children: palette.colors.map((hex) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(hex.substring(1), textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 7,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            ),
          )).toList()),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 50)),
    );
  }
}