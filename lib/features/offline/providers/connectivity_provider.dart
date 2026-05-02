import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';
import 'package:developer_os/features/notifications/providers/notification_provider.dart';
 
// ── Connection State ─────────────────────────────────────────────
enum ConnectionStatus { online, offline, reconnecting }
 
class ConnectivityState {
  final ConnectionStatus status;
  final DateTime? lastOnline;
  final int pendingSyncCount;
 
  const ConnectivityState({
    this.status = ConnectionStatus.online,
    this.lastOnline,
    this.pendingSyncCount = 0,
  });
 
  bool get isOnline => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;
 
  String get statusLabel {
    switch (status) {
      case ConnectionStatus.online: return 'Online';
      case ConnectionStatus.offline: return 'Offline';
      case ConnectionStatus.reconnecting: return 'Reconnecting...';
    }
  }
 
  ConnectivityState copyWith({
    ConnectionStatus? status,
    DateTime? lastOnline,
    int? pendingSyncCount,
  }) => ConnectivityState(
    status: status ?? this.status,
    lastOnline: lastOnline ?? this.lastOnline,
    pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
  );
}
 
// ── Connectivity Provider ────────────────────────────────────────
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier(ref);
});
 
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Ref _ref;
  Timer? _checkTimer;
  bool _wasOffline = false;
 
  ConnectivityNotifier(this._ref) : super(const ConnectivityState()) {
    _startMonitoring();
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
 
  void _startMonitoring() {
    // Check every 5 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    _check(); // Immediate first check
  }
 
  Future<void> _check() async {
    try {
      // Try DNS lookup as connectivity check
      await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
 
      if (state.status != ConnectionStatus.online) {
        // We're back online
        final pendingCount = _getPendingCount();
        state = state.copyWith(
          status: ConnectionStatus.online,
          lastOnline: DateTime.now(),
          pendingSyncCount: 0,
        );
 
        if (_wasOffline && pendingCount > 0) {
          // Notify about sync
          _ref.read(notifControllerProvider).offlineSynced(pendingCount);
          await _syncPendingChanges();
        }
        _wasOffline = false;
      } else {
        state = state.copyWith(lastOnline: DateTime.now());
      }
    } catch (_) {
      if (state.status == ConnectionStatus.online) {
        _wasOffline = true;
        state = state.copyWith(
          status: ConnectionStatus.offline,
          pendingSyncCount: _getPendingCount(),
        );
      }
    }
  }
 
  int _getPendingCount() {
    try {
      final box = Hive.box('developer_os_prefs');
      final pending = box.get('pending_sync', defaultValue: []);
      return (pending as List).length;
    } catch (_) {
      return 0;
    }
  }
 
  Future<void> _syncPendingChanges() async {
    try {
      final box = Hive.box('developer_os_prefs');
      final pending = List.from(box.get('pending_sync', defaultValue: []));
 
      for (final item in pending) {
        try {
          final map = Map<String, dynamic>.from(item as Map);
          final collection = map['collection'] as String;
          final docId = map['docId'] as String;
          final data = Map<String, dynamic>.from(map['data'] as Map);
          final operation = map['operation'] as String;
 
          final ref = FirebaseFirestore.instance.collection(collection).doc(docId);
 
          if (operation == 'set') {
            await ref.set(data, SetOptions(merge: true));
          } else if (operation == 'update') {
            await ref.update(data);
          } else if (operation == 'delete') {
            await ref.delete();
          }
        } catch (_) {
          // Skip failed items
        }
      }
 
      await box.put('pending_sync', []);
      state = state.copyWith(pendingSyncCount: 0);
    } catch (_) {}
  }
 
  /// Queue a Firestore operation for when back online
  Future<void> queueOperation({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    required String operation, // 'set', 'update', 'delete'
  }) async {
    try {
      final box = Hive.box('developer_os_prefs');
      final pending = List.from(box.get('pending_sync', defaultValue: []));
      pending.add({
        'collection': collection,
        'docId': docId,
        'data': data,
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await box.put('pending_sync', pending);
      state = state.copyWith(pendingSyncCount: pending.length);
    } catch (_) {}
  }
 
  Future<void> forceCheck() => _check();
 
  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
 
// ── Offline-Aware Firestore Helper ───────────────────────────────
class OfflineFirestore {
  final Ref _ref;
  OfflineFirestore(this._ref);
 
  bool get _isOnline => _ref.read(connectivityProvider).isOnline;
 
  Future<void> set(String path, Map<String, dynamic> data) async {
    final parts = path.split('/');
    final collection = parts.sublist(0, parts.length - 1).join('/');
    final docId = parts.last;
 
    if (_isOnline) {
      await FirebaseFirestore.instance.doc(path).set(data, SetOptions(merge: true));
    } else {
      // Save to Firestore cache (it handles offline automatically)
      FirebaseFirestore.instance.doc(path).set(data, SetOptions(merge: true));
      await _ref.read(connectivityProvider.notifier).queueOperation(
        collection: collection, docId: docId, data: data, operation: 'set',
      );
    }
  }
}
 
final offlineFirestoreProvider = Provider<OfflineFirestore>((ref) {
  return OfflineFirestore(ref);
});