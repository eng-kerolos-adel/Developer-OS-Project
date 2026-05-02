// import 'dart:async';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import './timer_notification_service.dart';

// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       // 🚨 رجعناها false عشان ميظهرش إشعار فاضي أول ما تفتح الأبلكيشن
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'developer_os_low',
//       initialNotificationTitle: 'Developer OS',
//       initialNotificationContent: 'Developer OS is Running in Background...',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   Timer? backgroundTimer;
//   int secondsRemaining = 0;
//   String phaseLabel = "Work";

//   service.on('startTimer').listen((event) {
//     backgroundTimer?.cancel();

//     if (event != null) {
//       secondsRemaining = event['secondsRemaining'] ?? 0;
//       phaseLabel = event['phaseLabel'] ?? "Work";
//     }

//     TimerNotificationService.showTimerNotification(
//       durationInSeconds: secondsRemaining,
//       phaseLabel: phaseLabel,
//       isPaused: false,
//     );

//     backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (secondsRemaining <= 0) {
//         timer.cancel();
//         service.invoke("timerCompleted");
//       } else {
//         secondsRemaining--;
//       }
//     });
//   });

//   service.on('pauseTimer').listen((event) {
//     backgroundTimer?.cancel();

//     // 🔥 التعديل السحري هنا عشان الـ Reset يمسح الإشعار
//     if (secondsRemaining <= 0) {
//       TimerNotificationService.cancelTimerNotification();
//     } else {
//       TimerNotificationService.showTimerNotification(
//         durationInSeconds: secondsRemaining,
//         phaseLabel: phaseLabel,
//         isPaused: true,
//       );
//     }
//   });

//   service.on('stopService').listen((event) {
//     backgroundTimer?.cancel();
//     service.stopSelf();
//   });
// }
