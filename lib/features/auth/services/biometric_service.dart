// lib/features/auth/services/biometric_service.dart
// ═══════════════════════════════════════════════════════════════════
// Biometric Authentication — Fingerprint + Face ID + PIN
// Packages needed:
//   local_auth: ^2.3.0
//   flutter_secure_storage: ^9.0.0  (already in pubspec)
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:developer_os/core/theme/app_theme.dart';
import 'package:developer_os/shared/widgets/glass_widgets.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/animated_background.dart';

// ═══════════════════════════════════════════════════════════════════
// Service
// ═══════════════════════════════════════════════════════════════════
class BiometricService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _pinKey         = 'devos_app_pin';
  static const _biometricKey   = 'devos_biometric_enabled';
  static const _lockEnabledKey = 'devos_app_lock_enabled';
  static const _lockTimeoutKey = 'devos_lock_timeout_minutes';

  static final LocalAuthentication _auth = LocalAuthentication();

  // ── Capability Check ─────────────────────────────────────────────
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) { return false; }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) { return []; }
  }

  static Future<String> getBiometricLabel() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris Scan';
    return 'Biometric';
  }

  // ── Settings ─────────────────────────────────────────────────────
  static Future<bool> isLockEnabled() async {
    return await _storage.read(key: _lockEnabledKey) == 'true';
  }

  static Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricKey) == 'true';
  }

  static Future<bool> hasPIN() async {
    final pin = await _storage.read(key: _pinKey);
    // لو الـ PIN مش موجود أو قيمته نص فاضي، هيرجع false 
    return pin != null && pin.isNotEmpty && pin != _hashPin('');
  }

  static Future<int> getLockTimeout() async {
    final val = await _storage.read(key: _lockTimeoutKey);
    return int.tryParse(val ?? '5') ?? 5;
  }

  static Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: _lockEnabledKey, value: enabled.toString());
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  static Future<void> setLockTimeout(int minutes) async {
    await _storage.write(key: _lockTimeoutKey, value: minutes.toString());
  }

  // ── PIN Management ───────────────────────────────────────────────
  static Future<void> setPIN(String pin) async {
    // Hash the PIN before storing
    final hashed = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hashed);
  }

  static Future<bool> verifyPIN(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored == _hashPin(pin);
  }

  static Future<void> clearPIN() async {
    await _storage.delete(key: _pinKey);
  }

  static String _hashPin(String pin) {
    // Simple deterministic hash for demo (use crypto package for production)
    var hash = 0;
    for (int i = 0; i < pin.length; i++) {
      hash = ((hash << 5) - hash) + pin.codeUnitAt(i);
      hash &= 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // ── Biometric Auth ───────────────────────────────────────────────
  static Future<BiometricResult> authenticate() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return BiometricResult.notAvailable;

      final didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate to access Developer OS',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );

      return didAuth ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) return BiometricResult.notEnrolled;
      if (e.code == auth_error.lockedOut) return BiometricResult.lockedOut;
      if (e.code == auth_error.permanentlyLockedOut) return BiometricResult.lockedOut;
      return BiometricResult.error;
    } catch (_) {
      return BiometricResult.error;
    }
  }

  // ── Disable All ──────────────────────────────────────────────────
  static Future<void> disableAll() async {
    await _storage.deleteAll();
  }
}

enum BiometricResult { success, failed, notAvailable, notEnrolled, lockedOut, error }

// ═══════════════════════════════════════════════════════════════════
// State Provider
// ═══════════════════════════════════════════════════════════════════
class AppLockState {
  final bool isLocked;
  final bool isLockEnabled;
  final bool isBiometricEnabled;
  final bool hasPIN;
  final bool isBiometricAvailable;
  final String biometricLabel;
  final int lockTimeoutMinutes;
  final DateTime? lastUnlocked;

  const AppLockState({
    this.isLocked = false,
    this.isLockEnabled = false,
    this.isBiometricEnabled = false,
    this.hasPIN = false,
    this.isBiometricAvailable = false,
    this.biometricLabel = 'Biometric',
    this.lockTimeoutMinutes = 5,
    this.lastUnlocked,
  });

  bool get shouldLock {
    if (!isLockEnabled) return false;
    if (lastUnlocked == null) return true;
    return DateTime.now().difference(lastUnlocked!).inMinutes >= lockTimeoutMinutes;
  }

  AppLockState copyWith({
    bool? isLocked, bool? isLockEnabled, bool? isBiometricEnabled,
    bool? hasPIN, bool? isBiometricAvailable, String? biometricLabel,
    int? lockTimeoutMinutes, DateTime? lastUnlocked,
  }) => AppLockState(
    isLocked: isLocked ?? this.isLocked,
    isLockEnabled: isLockEnabled ?? this.isLockEnabled,
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    hasPIN: hasPIN ?? this.hasPIN,
    isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
    biometricLabel: biometricLabel ?? this.biometricLabel,
    lockTimeoutMinutes: lockTimeoutMinutes ?? this.lockTimeoutMinutes,
    lastUnlocked: lastUnlocked ?? this.lastUnlocked,
  );
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier();
});

class AppLockNotifier extends StateNotifier<AppLockState> {
  AppLockNotifier() : super(const AppLockState()) { _load(); }

  Future<void> _load() async {
    final isEnabled     = await BiometricService.isLockEnabled();
    final isBio         = await BiometricService.isBiometricEnabled();
    final hasPin        = await BiometricService.hasPIN();
    final isAvail       = await BiometricService.isBiometricAvailable();
    final label         = await BiometricService.getBiometricLabel();
    final timeout       = await BiometricService.getLockTimeout();

    state = state.copyWith(
      isLockEnabled: isEnabled,
      isBiometricEnabled: isBio,
      hasPIN: hasPin,
      isBiometricAvailable: isAvail,
      biometricLabel: label,
      lockTimeoutMinutes: timeout,
      isLocked: isEnabled,
    );
  }

  Future<void> resetAll() async {
    // 1. هنصفر كل الداتا المتسجلة في الـ Local Storage (أو الـ Secure Storage)
    await BiometricService.setLockEnabled(false);
    await BiometricService.setBiometricEnabled(false);
    await BiometricService.clearPIN(); // بنصفر الـ PIN
    await BiometricService.setLockTimeout(5); // بنرجع التايم أوت للقيمة الافتراضية (مثلاً 5 دقائق)
    
    // 2. بنحدث الـ State في نفس اللحظة عشان الـ UI يفهم إن مفيش قفل خلاص
    state = state.copyWith(
      isLockEnabled: false,
      isBiometricEnabled: false,
      hasPIN: false,
      isLocked: false,
      lockTimeoutMinutes: 5,
      lastUnlocked: null, // بنمسح تاريخ آخر فتح
    );
    
    debugPrint("🚨 [AppLock] تم تصفير كافة إعدادات القفل بنجاح!");
  }

  Future<bool> authenticate() async {
    if (state.isBiometricEnabled && state.isBiometricAvailable) {
      final result = await BiometricService.authenticate();
      if (result == BiometricResult.success) {
        state = state.copyWith(isLocked: false, lastUnlocked: DateTime.now());
        return true;
      }
    }
    return false;
  }

  Future<bool> verifyPIN(String pin) async {
    final ok = await BiometricService.verifyPIN(pin);
    if (ok) {
      state = state.copyWith(isLocked: false, lastUnlocked: DateTime.now());
    }
    return ok;
  }

  Future<void> setPIN(String pin) async {
    await BiometricService.setPIN(pin);
    state = state.copyWith(hasPIN: true);
  }

  Future<void> enableBiometric() async {
    await BiometricService.setBiometricEnabled(true);
    state = state.copyWith(isBiometricEnabled: true);
  }

  Future<void> disableBiometric() async {
    await BiometricService.setBiometricEnabled(false);
    state = state.copyWith(isBiometricEnabled: false);
  }

  Future<void> setLockEnabled(bool v) async {
    await BiometricService.setLockEnabled(v);
    state = state.copyWith(isLockEnabled: v, isLocked: v);
  }

  Future<void> setLockTimeout(int min) async {
    await BiometricService.setLockTimeout(min);
    state = state.copyWith(lockTimeoutMinutes: min);
  }

  void lock() => state = state.copyWith(isLocked: true);
  void unlock() => state = state.copyWith(isLocked: false, lastUnlocked: DateTime.now());
}

// ═══════════════════════════════════════════════════════════════════
// Lock Screen Widget — shown when app is locked
// ═══════════════════════════════════════════════════════════════════
class AppLockScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryBiometric();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final lockState = ref.read(appLockProvider);
      if (lockState.isLockEnabled && lockState.shouldLock) {
        ref.read(appLockProvider.notifier).lock();
      }
    }
    if (state == AppLifecycleState.resumed) {
      final lockState = ref.read(appLockProvider);
      if (lockState.isLocked && lockState.isBiometricEnabled) {
        _tryBiometric();
      }
    }
  }

  Future<void> _tryBiometric() async {
    final lockState = ref.read(appLockProvider);
    if (!lockState.isLocked) return;
    if (lockState.isBiometricEnabled && lockState.isBiometricAvailable) {
      await ref.read(appLockProvider.notifier).authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    if (!lockState.isLocked) return widget.child;
    return _LockScreenUI(onUnlock: () {});
  }
}

// ── Lock Screen UI ───────────────────────────────────────────────
class _LockScreenUI extends ConsumerStatefulWidget {
  final VoidCallback onUnlock;
  const _LockScreenUI({required this.onUnlock});

  @override
  ConsumerState<_LockScreenUI> createState() => _LockScreenUIState();
}

class _LockScreenUIState extends ConsumerState<_LockScreenUI> {
  final List<String> _pin = [];
  bool _showPin = false;
  String? _error;
  bool _isVerifying = false;
  int _failedAttempts = 0;

  static const _maxAttempts = 5;

  Future<void> _onDigit(String d) async {
    if (_pin.length >= 6 || _isVerifying) return;
    setState(() { _pin.add(d); _error = null; });
    if (_pin.length == 6) await _verify();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() { _pin.removeLast(); _error = null; });
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    final ok = await ref.read(appLockProvider.notifier).verifyPIN(_pin.join());
    if (!mounted) return;

    if (ok) {
      widget.onUnlock();
    } else {
      _failedAttempts++;
      setState(() {
        _pin.clear();
        _isVerifying = false;
        _error = _failedAttempts >= _maxAttempts
            ? 'Too many attempts. Use biometric or sign out.'
            : 'Wrong PIN. ${_maxAttempts - _failedAttempts} attempts left.';
      });
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await ref.read(appLockProvider.notifier).authenticate();
    if (ok && mounted) widget.onUnlock();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lockState = ref.watch(appLockProvider);

    return Scaffold(
      body: AnimatedBackground(
        child: Column(children: [
          const Spacer(),

          // App icon + title
          Column(children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: (isDark ? AppTheme.white : AppTheme.black)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppTheme.white : AppTheme.black)
                              .withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.08),
                  ),
                  child: Center(
                    child: Text(
                      '</>', 
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ),
                ),

            const SizedBox(height: 20),

            Text('Developer OS',
                style: TextStyle(fontFamily: 'Syne', fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.white : AppTheme.black))
                .animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 6),

            Text('Enter your PIN to continue',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                    color: isDark ? AppTheme.gray : AppTheme.lightGray))
                .animate().fadeIn(delay: 300.ms),
          ]),

          const SizedBox(height: 40),

          // PIN dots
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = i < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? (isDark ? AppTheme.white : AppTheme.black)
                      : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.15),
                  boxShadow: filled ? [BoxShadow(
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.3),
                    blurRadius: 8,
                  )] : null,
                ),
              );
            }),
          ).animate().fadeIn(delay: 400.ms),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12,
                    color: Colors.red))
                .animate().shakeX(),
          ],

          const SizedBox(height: 40),

          // Numpad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(children: [
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['bio', '0', 'del'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((key) {
                      if (key == 'bio') {
                        if (!lockState.isBiometricEnabled) return const SizedBox(width: 76);
                        return _NumKey(
                          child: Icon(
                            lockState.biometricLabel == 'Face ID'
                                ? Icons.face
                                : Icons.fingerprint,
                            size: 28,
                            color: isDark ? AppTheme.white : AppTheme.black,
                          ),
                          onTap: _tryBiometric,
                          isDark: isDark,
                        );
                      }
                      if (key == 'del') {
                        return _NumKey(
                          child: Icon(Icons.backspace_outlined, size: 22,
                              color: isDark ? AppTheme.white : AppTheme.black),
                          onTap: _onDelete,
                          isDark: isDark,
                        );
                      }
                      return _NumKey(
                        child: Text(key, style: TextStyle(fontFamily: 'Syne',
                            fontSize: 24, fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.white : AppTheme.black)),
                        onTap: () => _onDigit(key),
                        isDark: isDark,
                      );
                    }).toList(),
                  ),
                ),
            ]),
          ).animate().fadeIn(delay: 500.ms),

          const Spacer(),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;
  const _NumKey({required this.child, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 76, height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07),
          border: Border.all(color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Security Settings Screen — goes inside SettingsScreen
// ═══════════════════════════════════════════════════════════════════
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _settingUpPIN = false;
  final List<String> _newPIN = [];
  final List<String> _confirmPIN = [];
  bool _confirmMode = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lockState = ref.watch(appLockProvider);
    final notifier = ref.read(appLockProvider.notifier);

    if (_settingUpPIN) {
      return _PINSetupView(
        newPIN: _newPIN,
        confirmPIN: _confirmPIN,
        confirmMode: _confirmMode,
        isDark: isDark,
        onDigit: (d) async {
          final list = _confirmMode ? _confirmPIN : _newPIN;
          if (list.length >= 6) return;
          setState(() => list.add(d));

          if (!_confirmMode && list.length == 6) {
            await Future.delayed(const Duration(milliseconds: 300));
            setState(() => _confirmMode = true);
          } else if (_confirmMode && list.length == 6) {
            if (_newPIN.join() == _confirmPIN.join()) {
              await notifier.setPIN(_newPIN.join());
              await notifier.setLockEnabled(true);
              if (mounted) {
                setState(() => _settingUpPIN = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('✅ PIN set successfully!',
                      style: TextStyle(fontFamily: 'JetBrainsMono')),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            } else {
              setState(() { _newPIN.clear(); _confirmPIN.clear(); _confirmMode = false; });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('PINs do not match. Try again.',
                    style: TextStyle(fontFamily: 'JetBrainsMono')),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
            }
          }
        },
        onDelete: () {
          setState(() {
            final list = _confirmMode ? _confirmPIN : _newPIN;
            if (list.isNotEmpty) list.removeLast();
          });
        },
        onCancel: () => setState(() {
          _settingUpPIN = false; _newPIN.clear();
          _confirmPIN.clear(); _confirmMode = false;
        }),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Back + Title
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 36, height: 36,
                padding: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)),
                child: Icon(Icons.arrow_back_ios, size: 16,
                    color: isDark ? AppTheme.white : AppTheme.black)),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('// security', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                  color: isDark ? AppTheme.gray : AppTheme.lightGray)),
              Text('App Lock', style: TextStyle(fontFamily: 'Syne', fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.white : AppTheme.black)),
            ]),
          ]).animate().fadeIn(),

          const SizedBox(height: 24),

          // Status card
          GlassCard(
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                    color: lockState.isLockEnabled
                        ? Colors.green.withOpacity(0.15)
                        : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.07)),
                child: Center(child: Icon(
                    lockState.isLockEnabled ? Icons.lock : Icons.lock_open,
                    color: lockState.isLockEnabled ? Colors.green : (isDark ? AppTheme.gray : AppTheme.lightGray)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lockState.isLockEnabled ? 'App Lock Enabled' : 'App Lock Disabled',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black)),
                Text(lockState.isLockEnabled
                    ? 'Your data is protected'
                    : 'Anyone can access your data',
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                        color: lockState.isLockEnabled ? Colors.green : Colors.orange)),
              ])),
              Switch(
                value: lockState.isLockEnabled,
                activeColor: Colors.green,
                onChanged: (v) async {
                  if (v && !lockState.hasPIN) {
                    setState(() => _settingUpPIN = true);
                  } else {
                    await notifier.setLockEnabled(v);
                  }
                },
              ),
            ]),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // PIN section
          _SectionHeader('PIN Code', isDark),
          const SizedBox(height: 10),

          GlassCard(child: Column(children: [
            _SettingRow(
              icon: Icons.pin_outlined,
              title: lockState.hasPIN ? 'Change PIN' : 'Set PIN',
              subtitle: lockState.hasPIN ? '6-digit PIN set' : 'No PIN set yet',
              isDark: isDark,
              onTap: () => setState(() {
                _settingUpPIN = true; _newPIN.clear();
                _confirmPIN.clear(); _confirmMode = false;
              }),
            ),
          ])),

          const SizedBox(height: 16),

          // Biometric section
          if (lockState.isBiometricAvailable) ...[
            _SectionHeader('Biometric', isDark),
            const SizedBox(height: 10),

            GlassCard(child: Column(children: [
              _SettingRow(
                icon: lockState.biometricLabel == 'Face ID' ? Icons.face : Icons.fingerprint,
                title: lockState.biometricLabel,
                subtitle: lockState.isBiometricEnabled
                    ? '${lockState.biometricLabel} enabled'
                    : 'Use ${lockState.biometricLabel} to unlock',
                isDark: isDark,
                trailing: Switch(
                  value: lockState.isBiometricEnabled,
                  activeColor: isDark ? AppTheme.white : AppTheme.black,
                  onChanged: lockState.hasPIN ? (v) async {
                    if (v) {
                      await notifier.enableBiometric();
                    } else {
                      await notifier.disableBiometric();
                    }
                  } : null,
                ),
              ),
            ])),

            if (!lockState.hasPIN)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text('Set a PIN first to enable ${lockState.biometricLabel}',
                    style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10,
                        color: Colors.orange)),
              ),

            const SizedBox(height: 16),
          ],

          // Auto-lock timeout
          if (lockState.isLockEnabled) ...[
            _SectionHeader('Auto-Lock', isDark),
            const SizedBox(height: 10),

            GlassCard(child: Column(
              children: [
                for (final (min, label) in [
                  (1, 'Immediately'), (2, '2 minutes'), (5, '5 minutes'),
                  (10, '10 minutes'), (30, '30 minutes'),
                ])
                  GestureDetector(
                    onTap: () => notifier.setLockTimeout(min),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Row(children: [
                        Icon(lockState.lockTimeoutMinutes == min
                            ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 20,
                            color: lockState.lockTimeoutMinutes == min
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : (isDark ? AppTheme.gray : AppTheme.lightGray)),
                        const SizedBox(width: 12),
                        Text(label, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                            color: lockState.lockTimeoutMinutes == min
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : (isDark ? AppTheme.gray : AppTheme.lightGray))),
                      ]),
                    ),
                  ),
              ],
            )),
            const SizedBox(height: 16),
          ],

          // Disable all
          if (lockState.isLockEnabled)
            GlassCard(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: isDark ? AppTheme.darkMid : AppTheme.white,
                    title: Text('Disable Security', style: TextStyle(fontFamily: 'Syne',
                        color: isDark ? AppTheme.white : AppTheme.black)),
                    content: Text('This will remove your PIN and biometric settings.',
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                            color: isDark ? AppTheme.silver : AppTheme.gray)),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('Disable', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await BiometricService.disableAll();
                  await notifier._load();
                }
              },
              child: Row(children: [
                const Icon(Icons.security_outlined, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Text('Disable All Security', style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                    fontWeight: FontWeight.w700, color: Colors.red)),
              ]),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PINSetupView extends StatelessWidget {
  final List<String> newPIN, confirmPIN;
  final bool confirmMode, isDark;
  final void Function(String) onDigit;
  final VoidCallback onDelete, onCancel;

  const _PINSetupView({
    required this.newPIN, required this.confirmPIN,
    required this.confirmMode, required this.isDark,
    required this.onDigit, required this.onDelete, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final current = confirmMode ? confirmPIN : newPIN;
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(onTap: onCancel,
              child: Icon(Icons.close, color: isDark ? AppTheme.gray : AppTheme.lightGray)),
            const Spacer(),
            Text(confirmMode ? 'Confirm PIN' : 'Set New PIN',
                style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.white : AppTheme.black)),
            const Spacer(), const SizedBox(width: 24),
          ]),
        ),
        const Spacer(),
        Text(confirmMode ? 'Re-enter your 6-digit PIN' : 'Choose a 6-digit PIN',
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13,
                color: isDark ? AppTheme.gray : AppTheme.lightGray)),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < current.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: filled ? (isDark ? AppTheme.white : AppTheme.black) : (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.15)),
            );
          })),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(children: [
            for (final row in [['1','2','3'], ['4','5','6'], ['7','8','9'], ['','0','del']])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((k) {
                    if (k.isEmpty) return const SizedBox(width: 76);
                    if (k == 'del') return _NumKey(
                      child: Icon(Icons.backspace_outlined, size: 22,
                          color: isDark ? AppTheme.white : AppTheme.black),
                      onTap: onDelete, isDark: isDark);
                    return _NumKey(
                      child: Text(k, style: TextStyle(fontFamily: 'Syne', fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.white : AppTheme.black)),
                      onTap: () => onDigit(k), isDark: isDark);
                  }).toList()),
              ),
          ]),
        ),
        const Spacer(),
      ]),
    );
  }
}

Widget _SectionHeader(String title, bool isDark) => Padding(
  padding: const EdgeInsets.only(left: 4),
  child: Text(title, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 1.5,
      color: isDark ? AppTheme.gray : AppTheme.lightGray)),
);

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingRow({required this.icon, required this.title, required this.subtitle,
      required this.isDark, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 22, color: isDark ? AppTheme.silver : AppTheme.gray),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.white : AppTheme.black)),
            Text(subtitle, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11,
                color: isDark ? AppTheme.gray : AppTheme.lightGray)),
          ])),
          trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios, size: 13,
              color: isDark ? AppTheme.gray : AppTheme.lightGray) : const SizedBox.shrink()),
        ]),
      ),
    );
  }
}