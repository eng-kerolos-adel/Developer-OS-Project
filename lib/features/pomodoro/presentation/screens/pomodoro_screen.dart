// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:developer_os/core/theme/app_theme.dart';
// import 'package:developer_os/shared/widgets/glass_widgets.dart';
// import 'package:developer_os/features/projects/providers/project_provider.dart';
// import 'package:developer_os/features/analytics/providers/analytics_provider.dart';
// import '../../../notifications/providers/notification_provider.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:developer_os/features/notifications/services/timer_notification_service.dart';

// // =====================
// // Pomodoro State
// // =====================
// enum PomodoroPhase { work, shortBreak, longBreak }

// class PomodoroState {
//   final PomodoroPhase phase;
//   final int secondsRemaining;
//   final bool isRunning;
//   final int completedSessions;
//   final String? selectedProjectId;
//   final String? selectedProjectName;

//   static const int workSeconds = 25 * 60;
//   static const int shortBreakSeconds = 5 * 60;
//   static const int longBreakSeconds = 15 * 60;

//   const PomodoroState({
//     this.phase = PomodoroPhase.work,
//     this.secondsRemaining = workSeconds,
//     this.isRunning = false,
//     this.completedSessions = 0,
//     this.selectedProjectId,
//     this.selectedProjectName,
//   });

//   int get totalSeconds {
//     switch (phase) {
//       case PomodoroPhase.work:
//         return workSeconds;
//       case PomodoroPhase.shortBreak:
//         return shortBreakSeconds;
//       case PomodoroPhase.longBreak:
//         return longBreakSeconds;
//     }
//   }

//   double get progress => 1.0 - (secondsRemaining / totalSeconds);

//   String get formattedTime {
//     final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
//     final s = (secondsRemaining % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   String get phaseLabel {
//     switch (phase) {
//       case PomodoroPhase.work:
//         return 'Focus Time';
//       case PomodoroPhase.shortBreak:
//         return 'Short Break';
//       case PomodoroPhase.longBreak:
//         return 'Long Break';
//     }
//   }

//   String get phaseEmoji {
//     switch (phase) {
//       case PomodoroPhase.work:
//         return '🍅';
//       case PomodoroPhase.shortBreak:
//         return '☕';
//       case PomodoroPhase.longBreak:
//         return '🌿';
//     }
//   }

//   PomodoroState copyWith({
//     PomodoroPhase? phase,
//     int? secondsRemaining,
//     bool? isRunning,
//     int? completedSessions,
//     String? selectedProjectId,
//     String? selectedProjectName,
//   }) {
//     return PomodoroState(
//       phase: phase ?? this.phase,
//       secondsRemaining: secondsRemaining ?? this.secondsRemaining,
//       isRunning: isRunning ?? this.isRunning,
//       completedSessions: completedSessions ?? this.completedSessions,
//       selectedProjectId: selectedProjectId ?? this.selectedProjectId,
//       selectedProjectName: selectedProjectName ?? this.selectedProjectName,
//     );
//   }
// }

// // =====================
// // Pomodoro Provider
// // =====================
// final pomodoroProvider =
//     StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
//   return PomodoroNotifier(ref);
// });

// class PomodoroNotifier extends StateNotifier<PomodoroState> {
//   final Ref _ref;
//   Timer? _timer;
//   DateTime? _sessionStart;

//   PomodoroNotifier(this._ref) : super(const PomodoroState());

//   void selectProject(String id, String name) {
//     state = state.copyWith(selectedProjectId: id, selectedProjectName: name);
//   }

//   void start() async {
//     if (state.isRunning) return;
//     _sessionStart = DateTime.now();
//     state = state.copyWith(isRunning: true);

//     // 1. تأكد إن السيرفس شغالة (لو لسه مصلين Pause هتكون شغالة بالفعل)
//     final service = FlutterBackgroundService();
//     bool isRunning = await service.isRunning();
//     if (!isRunning) {
//       service.startService();
//     }

//     // 🔥 التعديل السحري رقم 1: لازم نبعت الداتا للسيرفس عشان متقراش صفر!
//     service.invoke("startTimer", {
//       "secondsRemaining": state.secondsRemaining,
//       "phaseLabel": state.phaseLabel,
//     });

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (state.secondsRemaining <= 0) {
//         _onPhaseComplete();
//       } else {
//         state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
//       }
//     });
//   }

//   void pause() {
//     _timer?.cancel();
//     state = state.copyWith(isRunning: false);

//     // 🔥 2. السطر السحري: بنبعت إشارة للـ Service عشان توقف التايمر بتاعها هي كمان
//     FlutterBackgroundService().invoke("pauseTimer");
//   }

//   void reset() {
//     _timer?.cancel();

//     // 1. تصفير الـ State ورجوع العداد للوقت الأصلي (مثلاً 25 دقيقة)
//     state = PomodoroState(
//       selectedProjectId: state.selectedProjectId,
//       selectedProjectName: state.selectedProjectName,
//       secondsRemaining: 1500, // أو PomodoroState.workSeconds حسب إعداداتك
//       isRunning: false,
//     );

//     // 2. بنبلغ السيرفس تصفّر العداد من عندها هي كمان
//     FlutterBackgroundService().invoke("startTimer", {
//       "secondsRemaining": 0,
//       "phaseLabel": state.phaseLabel,
//     });

//     // 3. بنقول للسيرفس تاخد بوز، ولما تلاقي العداد بصفر هتمسح الإشعار تلقائياً!
//     FlutterBackgroundService().invoke("pauseTimer");

//     // 🔥 شيلنا الـ stopService عشان السيرفس متقفلش وتفضل جاهزة في الرام
//   }

//   void _onPhaseComplete() {
//     _timer?.cancel();

//     // 1. حساب الجلسات المكتملة وتحديد الـ Phase الجديدة أولاً
//     final bool isWorkPhase = state.phase == PomodoroPhase.work;
//     final int newCompleted =
//         isWorkPhase ? state.completedSessions + 1 : state.completedSessions;

//     PomodoroPhase nextPhase;
//     int nextSeconds;

//     if (isWorkPhase) {
//       // حفظ الجلسة في الداتا بيز
//       _saveSession();

//       // إرسال الإشعارات العادية
//       _ref.read(notifControllerProvider).pomodoroComplete(
//             newCompleted,
//             state.selectedProjectName,
//           );

//       // تحديد هل البريك اللي جاي طويل ولا قصير
//       if (newCompleted % 4 == 0) {
//         _ref.read(notifControllerProvider).pomodoroLongBreak(newCompleted);
//         nextPhase = PomodoroPhase.longBreak;
//         nextSeconds = PomodoroState.longBreakSeconds;
//       } else {
//         nextPhase = PomodoroPhase.shortBreak;
//         nextSeconds = PomodoroState.shortBreakSeconds;
//       }
//     } else {
//       // لو كنا في بريك وخلص، بنرجع للشغل
//       nextPhase = PomodoroPhase.work;
//       nextSeconds = 1500; // أو الوقت اللي إنت محدده للـ Work
//       _ref.read(notifControllerProvider).pomodoroBreakOver();
//     }

//     // 2. تحديث الـ State بالبيانات الجديدة (دي أهم خطوة تكون هنا)
//     state = PomodoroState(
//       phase: nextPhase,
//       secondsRemaining: nextSeconds,
//       completedSessions: newCompleted,
//       selectedProjectId: state.selectedProjectId,
//       selectedProjectName: state.selectedProjectName,
//       isRunning: false, // بنخليه واقف عشان ميبدأش البريك تلقائي لوحده
//     );

//     // // 3. قفل السيرفس ومسح الإشعار القديم في الآخر خاااالص بعد ما الـ State اتحدثت
//     // TimerNotificationService.cancelTimerNotification();
//     // FlutterBackgroundService().invoke("stopService");

//     print("🎯 Phase completed! Next phase: $nextPhase");
//   }

//   Future<void> _saveSession() async {
//     if (_sessionStart == null) return;
//     if (state.selectedProjectId == null) return;

//     final timer = _ref.read(activeTimerProvider.notifier);
//     timer.startFromPomodoro();

//     // Stop after work session duration
//     await timer.stop(note: 'Pomodoro session');
//     _sessionStart = null;
//   }

//   void skipPhase() {
//     _timer?.cancel();
//     _onPhaseComplete();
//     _saveSession();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }
// }

// // =====================
// // Pomodoro Screen
// // =====================
// class PomodoroScreen extends ConsumerStatefulWidget {
//   const PomodoroScreen({super.key});

//   @override
//   ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
// }

// class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _pulseCtrl;

//   @override
//   void initState() {
//     super.initState();
//     _pulseCtrl =
//         AnimationController(vsync: this, duration: const Duration(seconds: 2))
//           ..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _pulseCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final pomo = ref.watch(pomodoroProvider);
//     final projects = ref.watch(projectsProvider).asData?.value ?? [];

//     return SafeArea(
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // Header
//             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('// focus sessions',
//                     style: TextStyle(
//                         fontFamily: 'JetBrainsMono',
//                         fontSize: 11,
//                         color: isDark ? AppTheme.gray : AppTheme.lightGray)),
//                 Text('Pomodoro',
//                     style: TextStyle(
//                         fontFamily: 'Syne',
//                         fontSize: 22,
//                         fontWeight: FontWeight.w800,
//                         color: isDark ? AppTheme.white : AppTheme.black)),
//               ]),
//               // Session counter
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: (isDark ? AppTheme.white : AppTheme.black)
//                       .withOpacity(0.07),
//                   border: Border.all(
//                       color: (isDark ? AppTheme.white : AppTheme.black)
//                           .withOpacity(0.1)),
//                 ),
//                 child: Row(children: [
//                   Text('🍅 ', style: const TextStyle(fontSize: 14)),
//                   Text('${pomo.completedSessions}',
//                       style: TextStyle(
//                           fontFamily: 'Syne',
//                           fontSize: 18,
//                           fontWeight: FontWeight.w800,
//                           color: isDark ? AppTheme.white : AppTheme.black)),
//                   Text(' sessions',
//                       style: TextStyle(
//                           fontFamily: 'JetBrainsMono',
//                           fontSize: 10,
//                           color: isDark ? AppTheme.gray : AppTheme.lightGray)),
//                 ]),
//               ),
//             ]).animate().fadeIn(),

//             const SizedBox(height: 32),

//             // Phase indicator
//             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               for (final phase in PomodoroPhase.values) ...[
//                 GestureDetector(
//                   onTap: () {
//                     if (!pomo.isRunning) {
//                       ref.read(pomodoroProvider.notifier).reset();
//                     }
//                   },
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       color: pomo.phase == phase
//                           ? (isDark ? AppTheme.white : AppTheme.black)
//                           : Colors.transparent,
//                       border: Border.all(
//                           color: pomo.phase == phase
//                               ? Colors.transparent
//                               : (isDark ? AppTheme.white : AppTheme.black)
//                                   .withOpacity(0.15)),
//                     ),
//                     child: Text(
//                       phase == PomodoroPhase.work
//                           ? 'Focus'
//                           : phase == PomodoroPhase.shortBreak
//                               ? 'Short Break'
//                               : 'Long Break',
//                       style: TextStyle(
//                           fontFamily: 'JetBrainsMono',
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: pomo.phase == phase
//                               ? (isDark ? AppTheme.black : AppTheme.white)
//                               : (isDark ? AppTheme.gray : AppTheme.lightGray)),
//                     ),
//                   ),
//                 ),
//                 if (phase != PomodoroPhase.longBreak) const SizedBox(width: 8),
//               ],
//             ]).animate().fadeIn(delay: 100.ms),

//             const SizedBox(height: 40),

//             // Timer Circle
//             AnimatedBuilder(
//               animation: _pulseCtrl,
//               builder: (context, child) {
//                 final pulse = pomo.isRunning ? _pulseCtrl.value * 0.05 : 0.0;
//                 return Transform.scale(
//                   scale: 1.0 + pulse,
//                   child: child,
//                 );
//               },
//               child: SizedBox(
//                 width: 260,
//                 height: 260,
//                 child: CustomPaint(
//                   painter: _TimerPainter(
//                     progress: pomo.progress,
//                     isDark: isDark,
//                     isRunning: pomo.isRunning,
//                     phase: pomo.phase,
//                   ),
//                   child: Center(
//                     child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(pomo.phaseEmoji,
//                               style: const TextStyle(fontSize: 32)),
//                           const SizedBox(height: 4),
//                           Text(pomo.formattedTime,
//                               style: TextStyle(
//                                   fontFamily: 'JetBrainsMono',
//                                   fontSize: 52,
//                                   fontWeight: FontWeight.w700,
//                                   color: isDark
//                                       ? AppTheme.white
//                                       : AppTheme.black)),
//                           Text(pomo.phaseLabel,
//                               style: TextStyle(
//                                   fontFamily: 'JetBrainsMono',
//                                   fontSize: 12,
//                                   color: isDark
//                                       ? AppTheme.gray
//                                       : AppTheme.lightGray,
//                                   letterSpacing: 1)),
//                         ]),
//                   ),
//                 ),
//               ),
//             ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

//             const SizedBox(height: 40),

//             // Controls
//             Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//               // Reset
//               GestureDetector(
//                 onTap: () => ref.read(pomodoroProvider.notifier).reset(),
//                 child: Container(
//                   width: 52,
//                   height: 52,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: (isDark ? AppTheme.white : AppTheme.black)
//                         .withOpacity(0.07),
//                   ),
//                   child: Icon(Icons.refresh,
//                       color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                       size: 22),
//                 ),
//               ),
//               const SizedBox(width: 20),

//               // Play/Pause
//               GestureDetector(
//                 onTap: () {
//                   if (pomo.isRunning) {
//                     ref.read(pomodoroProvider.notifier).pause();
//                   } else {
//                     ref.read(pomodoroProvider.notifier).start();
//                   }
//                 },
//                 child: Container(
//                   width: 72,
//                   height: 72,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: isDark ? AppTheme.white : AppTheme.black,
//                     boxShadow: [
//                       BoxShadow(
//                         color: (isDark ? AppTheme.white : AppTheme.black)
//                             .withOpacity(0.3),
//                         blurRadius: 20,
//                         spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     pomo.isRunning ? Icons.pause : Icons.play_arrow,
//                     color: isDark ? AppTheme.black : AppTheme.white,
//                     size: 32,
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 20),

//               // Skip
//               GestureDetector(
//                 onTap: () => ref.read(pomodoroProvider.notifier).skipPhase(),
//                 child: Container(
//                   width: 52,
//                   height: 52,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: (isDark ? AppTheme.white : AppTheme.black)
//                         .withOpacity(0.07),
//                   ),
//                   child: Icon(Icons.skip_next,
//                       color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                       size: 22),
//                 ),
//               ),
//             ]).animate().fadeIn(delay: 200.ms),

//             const SizedBox(height: 32),

//             // Project selector
//             if (projects.isNotEmpty) ...[
//               Text('Link to Project',
//                   style: TextStyle(
//                       fontFamily: 'JetBrainsMono',
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                       color: isDark ? AppTheme.gray : AppTheme.lightGray,
//                       letterSpacing: 1.5)),
//               const SizedBox(height: 10),
//               GlassCard(
//                 padding: EdgeInsets.zero,
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     value: pomo.selectedProjectId,
//                     isExpanded: true,
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     hint: Text('Select project to track time',
//                         style: TextStyle(
//                             fontFamily: 'JetBrainsMono',
//                             fontSize: 13,
//                             color:
//                                 isDark ? AppTheme.gray : AppTheme.lightGray)),
//                     dropdownColor: isDark ? AppTheme.darkMid : AppTheme.white,
//                     style: TextStyle(
//                         fontFamily: 'JetBrainsMono',
//                         fontSize: 13,
//                         color: isDark ? AppTheme.white : AppTheme.black),
//                     items: projects
//                         .map((p) =>
//                             DropdownMenuItem(value: p.id, child: Text(p.name)))
//                         .toList(),
//                     onChanged: (id) {
//                       if (id == null) return;
//                       final p = projects.firstWhere((p) => p.id == id);
//                       ref
//                           .read(pomodoroProvider.notifier)
//                           .selectProject(id, p.name);
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],

//             // Tips
//             GlassCard(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Pomodoro Technique',
//                         style: TextStyle(
//                             fontFamily: 'Syne',
//                             fontSize: 14,
//                             fontWeight: FontWeight.w700,
//                             color: isDark ? AppTheme.white : AppTheme.black)),
//                     const SizedBox(height: 8),
//                     for (final tip in [
//                       '🍅 Work for 25 minutes',
//                       '☕ Short break: 5 minutes',
//                       '🌿 Long break after 4 sessions: 15 minutes',
//                       '🔄 Repeat cycle for deep focus',
//                     ])
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 4),
//                         child: Text(tip,
//                             style: TextStyle(
//                                 fontFamily: 'JetBrainsMono',
//                                 fontSize: 11,
//                                 height: 1.5,
//                                 color: isDark
//                                     ? AppTheme.gray
//                                     : AppTheme.lightGray)),
//                       ),
//                   ]),
//             ).animate().fadeIn(delay: 300.ms),

//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // =====================
// // Timer Circle Painter
// // =====================
// class _TimerPainter extends CustomPainter {
//   final double progress;
//   final bool isDark;
//   final bool isRunning;
//   final PomodoroPhase phase;

//   _TimerPainter({
//     required this.progress,
//     required this.isDark,
//     required this.isRunning,
//     required this.phase,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2 - 10;

//     // Background circle
//     final bgPaint = Paint()
//       ..color = (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.06)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 8
//       ..strokeCap = StrokeCap.round;

//     canvas.drawCircle(center, radius, bgPaint);

//     // Progress arc
//     final progressPaint = Paint()
//       ..color = _phaseColor()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 8
//       ..strokeCap = StrokeCap.round;

//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -math.pi / 2,
//       2 * math.pi * progress,
//       false,
//       progressPaint,
//     );

//     // Dot at progress position
//     if (progress > 0) {
//       final angle = -math.pi / 2 + 2 * math.pi * progress;
//       final dotOffset = Offset(
//         center.dx + radius * math.cos(angle),
//         center.dy + radius * math.sin(angle),
//       );
//       final dotPaint = Paint()..color = _phaseColor();
//       canvas.drawCircle(dotOffset, 6, dotPaint);
//     }
//   }

//   Color _phaseColor() {
//     switch (phase) {
//       case PomodoroPhase.work:
//         return Colors.redAccent;
//       case PomodoroPhase.shortBreak:
//         return Colors.greenAccent.shade400;
//       case PomodoroPhase.longBreak:
//         return Colors.blueAccent;
//     }
//   }

//   @override
//   bool shouldRepaint(_TimerPainter old) =>
//       old.progress != progress || old.isRunning != isRunning;
// }
