import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:developer_os/features/interview/domain/models/interview_models.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';

// =====================
// Repository
// =====================
final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository(firestore: FirebaseFirestore.instance);
});

class InterviewRepository {
  final FirebaseFirestore _firestore;
  InterviewRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _apps(String uid) =>
      _firestore.collection('users').doc(uid).collection('interviews');

  CollectionReference _dsa(String uid) =>
      _firestore.collection('users').doc(uid).collection('dsa_problems');

  // Applications
  Stream<List<InterviewApplication>> watchApplications(String uid) {
    return _apps(uid)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => InterviewApplication.fromMap(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addApplication(String uid, InterviewApplication app) async {
    await _apps(uid).doc(app.id).set(app.toMap());
  }

  Future<void> updateApplication(String uid, InterviewApplication app) async {
    await _apps(uid).doc(app.id).update(app.toMap());
  }

  Future<void> deleteApplication(String uid, String appId) async {
    await _apps(uid).doc(appId).delete();
  }

  // DSA Problems
  Stream<List<DSAProblem>> watchProblems(String uid) {
    return _dsa(uid)
        .orderBy('category')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                DSAProblem.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addProblem(String uid, DSAProblem problem) async {
    await _dsa(uid).doc(problem.id).set(problem.toMap());
  }

  Future<void> updateProblem(String uid, DSAProblem problem) async {
    await _dsa(uid).doc(problem.id).update(problem.toMap());
  }

  Future<void> deleteProblem(String uid, String problemId) async {
    await _dsa(uid).doc(problemId).delete();
  }
}

// =====================
// Providers
// =====================
final applicationsProvider =
    StreamProvider<List<InterviewApplication>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(interviewRepositoryProvider).watchApplications(user.uid);
});

final dsaProblemsProvider = StreamProvider<List<DSAProblem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(interviewRepositoryProvider).watchProblems(user.uid);
});

final interviewControllerProvider =
    StateNotifierProvider<InterviewController, AsyncValue<void>>((ref) {
  return InterviewController(ref);
});

class InterviewController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  InterviewController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  Future<void> addApplication({
    required String company,
    required String position,
    String? jobUrl,
    String? notes,
    int? salaryMin,
    int? salaryMax,
  }) async {
    final app = InterviewApplication(
      id: const Uuid().v4(),
      uid: _uid,
      company: company,
      position: position,
      appliedDate: DateTime.now(),
      jobUrl: jobUrl,
      notes: notes,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );
    await _ref.read(interviewRepositoryProvider).addApplication(_uid, app);
  }

  Future<void> updateStatus(InterviewApplication app, String status) async {
    await _ref
        .read(interviewRepositoryProvider)
        .updateApplication(_uid, app.copyWith(status: status));
  }

  Future<void> deleteApplication(String id) async {
    await _ref.read(interviewRepositoryProvider).deleteApplication(_uid, id);
  }

  Future<void> addDSAProblem({
    required String title,
    required String difficulty,
    required String category,
    String? leetcodeUrl,
  }) async {
    final problem = DSAProblem(
      id: const Uuid().v4(),
      uid: _uid,
      title: title,
      difficulty: difficulty,
      category: category,
      leetcodeUrl: leetcodeUrl,
    );
    await _ref.read(interviewRepositoryProvider).addProblem(_uid, problem);
  }

  Future<void> toggleProblemSolved(DSAProblem problem) async {
    final updated = problem.copyWith(
      isSolved: !problem.isSolved,
      solvedAt: !problem.isSolved ? DateTime.now() : null,
    );
    await _ref
        .read(interviewRepositoryProvider)
        .updateProblem(_uid, updated);
  }

  Future<void> deleteProblem(String problemId) async {
    await _ref
        .read(interviewRepositoryProvider)
        .deleteProblem(_uid, problemId);
  }
}