// lib/features/notifications/services/push_notification_service.dart
//
// Firebase Cloud Messaging — Push Notifications to Device
// =========================================================
// Setup steps (in INTEGRATION_GUIDE):
//   1. Enable FCM in Firebase Console
//   2. Add google-services.json (already done)
//   3. Add firebase_messaging to pubspec.yaml
//   4. Add Android notification channel setup
//   5. Add iOS permissions in Info.plist

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/notifications/domain/models/notification_models.dart';

// ─────────────────────────────────────────────────────────────────────
// Background handler — must be top-level function
// ─────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show local notification when app is in background/terminated
  await PushNotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Developer OS',
    body: message.notification?.body ?? '',
    payload: jsonEncode(message.data),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Push Notification Service
// ─────────────────────────────────────────────────────────────────────
class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  // Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'developer_os_high',
    'Developer OS Notifications',
    description: 'All Developer OS notifications',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
  );

  static const AndroidNotificationChannel _channelSilent =
      AndroidNotificationChannel(
    'developer_os_low',
    'Developer OS — Low Priority',
    description: 'Non-urgent notifications like digests',
    importance: Importance.low,
    enableVibration: false,
    playSound: false,
  );

  // ── Initialize ─────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Initialize local notifications
    await _initLocalNotifications();

    // Create Android channels
    await _createAndroidChannels();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Handle background tap (app in background, user taps notif)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Handle terminated tap (app killed, user taps notif)
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    debugPrint('✅ Push notifications initialized');
  }

  static Future<void> _initLocalNotifications() async {
    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifs.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        // Handle tap on local notification
        if (details.payload != null) {
          _handleLocalTap(details.payload!);
        }
      },
    );
  }

  static Future<void> _createAndroidChannels() async {
    if (!Platform.isAndroid) return;
    final plugin = _localNotifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(_channel);
    await plugin?.createNotificationChannel(_channelSilent);
  }

  // ── Handle Messages ────────────────────────────────────────────────
  static void _handleForeground(RemoteMessage message) {
    // When app is open — show local notification
    showLocalNotification(
      title: message.notification?.title ?? 'Developer OS',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
      isUrgent: message.data['priority'] == 'urgent' ||
          message.data['priority'] == 'high',
    );
  }

  static void _handleTap(RemoteMessage message) {
    // Navigate based on notification type
    final type = message.data['type'] ?? '';
    debugPrint('Notification tapped: $type → ${message.data}');
    // Navigation handled by NotificationNavigator below
  }

  static void _handleLocalTap(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('Local notification tapped: $data');
    } catch (_) {}
  }

  // ── Show Local Notification ────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isUrgent = true,
  }) async {
    final channelId = isUrgent ? 'developer_os_high' : 'developer_os_low';
    final importance = isUrgent ? Importance.max : Importance.low;
    final priority = isUrgent ? Priority.high : Priority.low;

    await _localNotifs.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isUrgent
              ? 'Developer OS Notifications'
              : 'Developer OS — Low Priority',
          importance: importance,
          priority: priority,
          icon: '@drawable/notification_icon',
          styleInformation: BigTextStyleInformation(body),
          enableVibration: isUrgent,
          playSound: isUrgent,
          color: const Color(0xFF1A1A1A),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: isUrgent,
          interruptionLevel: isUrgent
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.passive,
        ),
      ),
      payload: payload,
    );
  }

  // ── FCM Token Management ───────────────────────────────────────────
  static Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('✅ FCM token saved: ${token.substring(0, 20)}...');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .doc(newToken)
            .set({
          'token': newToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      });
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  static Future<void> removeTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .delete();

      await _fcm.deleteToken();
    } catch (_) {}
  }

  // ── Send Push Directly (without Cloud Functions) ──────────────────
  // For client-side scheduling (e.g., local reminders via local notifications)
  static Future<void> scheduleLocal({
    required String title,
    required String body,
    required Duration delay,
    String? payload,
    bool isUrgent = false,
  }) async {
    // Show after delay using a simple timer approach
    await Future.delayed(delay);
    await showLocalNotification(
        title: title, body: body, payload: payload, isUrgent: isUrgent);
  }

  // ── Badge Management ───────────────────────────────────────────────
  static Future<void> updateBadge(int count) async {
    if (Platform.isIOS) {
      await _localNotifs
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(badge: true);
    }
  }

  static Future<void> clearBadge() async {
    await _localNotifs.cancelAll();
  }

  // ── Check Permission Status ────────────────────────────────────────
  static Future<bool> hasPermission() async {
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> openSettings() async {
    await _fcm.requestPermission();
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

final fcmPermissionProvider = FutureProvider<bool>((ref) async {
  return PushNotificationService.hasPermission();
});
