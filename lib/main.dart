// lib/main.dart

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:developer_os/core/router/app_router.dart';
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/core/providers/theme_provider.dart';
import 'package:developer_os/firebase_options.dart';
import 'package:developer_os/features/notifications/services/push_notification_service.dart';
import 'package:developer_os/features/notifications/providers/notification_provider.dart';
import 'package:developer_os/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:developer_os/features/updates/update_system.dart';
import './features/auth/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 استوردنا دي
import './features/github/providers/github_provider.dart';
import './features/ai/services/ai_provider.dart';

// ✅ Background handler — يجب أن يكون top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // نهيئ Firebase لو مش متهيئ
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // نعرض الإشعار على الجهاز
  await PushNotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Developer OS',
    body: message.notification?.body ?? '',
    payload: jsonEncode(message.data),
    isUrgent: message.data['priority'] == 'urgent' ||
        message.data['priority'] == 'high',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // 2. Register FCM background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 3. Initialize push notifications
  await PushNotificationService.initialize();

  // 4. Hive local storage
  await Hive.initFlutter();
  await Hive.openBox('developer_os_prefs');

  // 🔥 5. قراءة الـ GitHub Token من الـ SharedPreferences
  // عشان نضمن إنه مستحيل يتمسح في الهوت ريستارت التاني
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('github_token');
  final savedGeminiKey = prefs.getString('gemini_api_key');

  // 6. Status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        // 👈 هنا بنحقن الـ Token اللي قريناه في الـ Provider المخصص له
        githubTokenProvider.overrideWith(
          (ref) => GitHubTokenNotifier(ref, savedToken),
        ),
        aiApiKeyProvider.overrideWith(
          (ref) => AIKeyNotifier(savedGeminiKey),
        ),
      ],
      child: const DeveloperOSApp(),
    ),
  );
}

class DeveloperOSApp extends ConsumerWidget {
  const DeveloperOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // ✅ نشغّل الـ systems هنا — بدون autoDispose عشان يفضلوا شغالين
    ref.watch(backgroundAchievementObserver); // مراقبة الإنجازات
    ref.read(notifSchedulerProvider); // جدولة الإشعارات
    ref.read(updateProvider); // فحص التحديثات

    return MaterialApp.router(
      title: 'Developer OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // هنا بقى السحر كله 👇
      builder: (context, child) {
        return AppLockScreen(child: child!);
      },
    );
  }
}
