// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class TimerNotificationService {
//   static final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();

//   static const AndroidNotificationChannel _timerChannel = AndroidNotificationChannel(
//     'developer_os_high',
//     'Developer OS — Pomodoro Timer',
//     description: 'Notifications for the Pomodoro countdown timer',
//     importance: Importance.max,
//     enableVibration: false,
//     playSound: false,
//   );

//   static String _formatDuration(int totalSeconds) {
//     final minutes = totalSeconds ~/ 60;
//     final seconds = totalSeconds % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//   }

//   static Future<void> showTimerNotification({
//     required int durationInSeconds,
//     required String phaseLabel,
//     bool isPaused = false,
//   }) async {
//     if (!Platform.isAndroid) return;

//     final String timeFormatted = _formatDuration(durationInSeconds);
//     final int whenValue = DateTime.now().millisecondsSinceEpoch + (durationInSeconds * 1000);

//     await _localNotifs.show(
//       2026,
//       '$phaseLabel session is active 🍅',
//       isPaused ? 'Timer paused at $timeFormatted' : 'Time is ticking...',
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           _timerChannel.id,
//           _timerChannel.name,
//           channelDescription: _timerChannel.description,
//           importance: _timerChannel.importance,
//           priority: Priority.high,
//           ongoing: true,

//           showWhen: !isPaused, 
//           when: isPaused ? null : whenValue, 
//           usesChronometer: !isPaused, 
//           chronometerCountDown: !isPaused,

//           icon: '@drawable/notification_icon',
//           color: const Color(0xFF1A1A1A),
//           styleInformation: BigTextStyleInformation(
//             isPaused ? 'Timer paused at $timeFormatted' : 'Time is ticking...',
//           ),
//         ),
//       ),
//     );
//   }

//   // الدالة اللي الشاشة معترضة عليها رجعت اهي 👇
//   static Future<void> cancelTimerNotification() async {
//     await _localNotifs.cancel(2026);
//   }
// }