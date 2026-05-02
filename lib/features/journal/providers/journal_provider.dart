import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:developer_os/features/journal/domain/models/journal_entry.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';

// =====================
// Repository
// =====================
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(firestore: FirebaseFirestore.instance);
});

class JournalRepository {
  final FirebaseFirestore _firestore;

  JournalRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('journal');

  Stream<List<JournalEntry>> watchEntries(String uid) {
    return _col(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                JournalEntry.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addEntry(String uid, JournalEntry entry) async {
    await _col(uid).doc(entry.id).set(entry.toMap());
  }

  Future<void> updateEntry(String uid, JournalEntry entry) async {
    await _col(uid).doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteEntry(String uid, String entryId) async {
    await _col(uid).doc(entryId).delete();
  }
}

// =====================
// Providers
// =====================
final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(journalRepositoryProvider).watchEntries(user.uid);
});

final journalControllerProvider =
    StateNotifierProvider<JournalController, AsyncValue<void>>((ref) {
  return JournalController(ref);
});

class JournalController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  JournalController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  Future<void> addEntry({
    required String content,
    required List<String> tags,
    required String mood,
    required int productivityScore,
    required DateTime date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entry = JournalEntry(
        id: const Uuid().v4(),
        uid: _uid,
        content: content,
        tags: tags,
        mood: mood,
        productivityScore: productivityScore,
        date: date,
        createdAt: DateTime.now(),
      );
      await _ref.read(journalRepositoryProvider).addEntry(_uid, entry);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await _ref.read(journalRepositoryProvider).deleteEntry(_uid, entryId);
  }
}