import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../../notifications/services/push_notification_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

// Auth controller state
enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.idle, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState());

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.signInWithEmail(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
      // تعديل السطر هنا لجلب الـ uid
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await PushNotificationService.saveTokenForUser(currentUser.uid);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repo.registerWithEmail(
          email: email, password: password, displayName: name);
      state = state.copyWith(status: AuthStatus.success);
      // تعديل السطر هنا لجلب الـ uid
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await PushNotificationService.saveTokenForUser(currentUser.uid);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e.code),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final result = await _repo.signInWithGoogle();
      if (result == null) {
        state = state.copyWith(status: AuthStatus.idle);
        return false;
      }
      state = state.copyWith(status: AuthStatus.success);
      // تعديل السطر هنا لجلب الـ uid
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await PushNotificationService.saveTokenForUser(currentUser.uid);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google sign-in failed. Try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await PushNotificationService.removeTokenForUser(currentUser.uid);
    }
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.idle, errorMessage: null);
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
