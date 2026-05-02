// lib/core/services/monitoring_service.dart
// ═══════════════════════════════════════════════════════════════════
// Firebase Crashlytics + Analytics + Performance
// ═══════════════════════════════════════════════════════════════════
// Packages to add in pubspec.yaml:
//   firebase_crashlytics: ^3.5.7
//   firebase_analytics: ^10.10.7
//   firebase_performance: ^0.9.4+7

import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════
// Monitoring Service — single entry point for all tracking
// ═══════════════════════════════════════════════════════════════════
class MonitoringService {
  static final _analytics    = FirebaseAnalytics.instance;
  static final _crashlytics  = FirebaseCrashlytics.instance;
  static final _performance  = FirebasePerformance.instance;

  // ── Initialize (call once in main()) ───────────────────────────
  static Future<void> initialize() async {
    // Crashlytics: catch all Flutter errors
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Catch async errors outside Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Disable in debug mode
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    await _performance.setPerformanceCollectionEnabled(!kDebugMode);

    debugPrint('✅ Monitoring initialized');
  }

  // ── Set User Identity ────────────────────────────────────────────
  static Future<void> setUser(String uid, String? email) async {
    await _crashlytics.setUserIdentifier(uid);
    await _analytics.setUserId(id: uid);
    if (email != null) {
      await _crashlytics.setCustomKey('email', email);
    }
  }

  static Future<void> clearUser() async {
    await _analytics.setUserId(id: null);
  }

  // ── Screen Tracking ──────────────────────────────────────────────
  static Future<void> logScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // ── Events ───────────────────────────────────────────────────────

  // Auth
  static Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  static Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  // Projects
  static Future<void> logProjectCreated(String type) =>
      _analytics.logEvent(name: 'project_created', parameters: {'type': type});

  static Future<void> logProjectCompleted() =>
      _analytics.logEvent(name: 'project_completed');

  // Pomodoro
  static Future<void> logPomodoroComplete(int sessionNum) =>
      _analytics.logEvent(name: 'pomodoro_complete',
          parameters: {'session_number': sessionNum});

  // Achievements
  // static Future<void> logAchievementUnlocked(String achievementId) =>
  //     _analytics.logUnlockAchievement(achievementId: achievementId);

  // Feature usage
  static Future<void> logFeatureUsed(String feature) =>
      _analytics.logEvent(name: 'feature_used',
          parameters: {'feature': feature});

  // AI usage
  static Future<void> logAIGenerate(String type) =>
      _analytics.logEvent(name: 'ai_generate',
          parameters: {'type': type});

  // Freelance
  static Future<void> logInvoiceCreated(double amount) =>
      _analytics.logEvent(name: 'invoice_created',
          parameters: {'amount': amount.round()});

  // Onboarding
  static Future<void> logOnboardingStep(int step) =>
      _analytics.logEvent(name: 'onboarding_step',
          parameters: {'step': step});

  static Future<void> logOnboardingComplete() =>
      _analytics.logEvent(name: 'onboarding_complete');

  // Subscription
  static Future<void> logProUpgrade(String plan) =>
      _analytics.logEvent(name: 'pro_upgrade',
          parameters: {'plan': plan});

  // ── Performance Traces ───────────────────────────────────────────
  static Future<T> trace<T>(String name, Future<T> Function() fn) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    try {
      final result = await fn();
      await trace.stop();
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      await trace.stop();
      rethrow;
    }
  }

  // ── Error Logging ────────────────────────────────────────────────
  static Future<void> logError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error, stack,
      reason: reason,
      fatal: fatal,
    );
  }

  static void addBreadcrumb(String key, String value) {
    _crashlytics.setCustomKey(key, value);
  }
}

// ── Provider ─────────────────────────────────────────────────────
final monitoringProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});

// ── NavigatorObserver for automatic screen tracking ──────────────
class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      MonitoringService.logScreen(route.settings.name!);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      MonitoringService.logScreen(newRoute!.settings.name!);
    }
  }
}
