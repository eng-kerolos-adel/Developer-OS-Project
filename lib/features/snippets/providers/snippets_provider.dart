import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:developer_os/features/snippets/domain/models/code_snippet.dart';
import 'package:developer_os/features/auth/providers/auth_provider.dart';

final snippetsRepositoryProvider = Provider<SnippetsRepository>((ref) {
  return SnippetsRepository(firestore: FirebaseFirestore.instance);
});

class SnippetsRepository {
  final FirebaseFirestore _firestore;

  SnippetsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('snippets');

  Stream<List<CodeSnippet>> watchSnippets(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                CodeSnippet.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addSnippet(String uid, CodeSnippet snippet) async {
    await _col(uid).doc(snippet.id).set(snippet.toMap());
  }

  Future<void> updateSnippet(String uid, CodeSnippet snippet) async {
    await _col(uid).doc(snippet.id).update(snippet.toMap());
  }

  Future<void> deleteSnippet(String uid, String snippetId) async {
    await _col(uid).doc(snippetId).delete();
  }
}

final snippetsProvider = StreamProvider<List<CodeSnippet>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(snippetsRepositoryProvider).watchSnippets(user.uid);
});

final snippetsControllerProvider =
    StateNotifierProvider<SnippetsController, AsyncValue<void>>((ref) {
  return SnippetsController(ref);
});

class SnippetsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SnippetsController(this._ref) : super(const AsyncValue.data(null));

  String get _uid => _ref.read(currentUserProvider)?.uid ?? '';

  Future<void> addSnippet({
    required String title,
    required String code,
    required String language,
    List<String> tags = const [],
    String? description,
  }) async {
    final snippet = CodeSnippet(
      id: const Uuid().v4(),
      uid: _uid,
      title: title,
      code: code,
      language: language,
      tags: tags,
      description: description,
      createdAt: DateTime.now(),
    );
    await _ref.read(snippetsRepositoryProvider).addSnippet(_uid, snippet);
  }

  Future<void> toggleFavorite(CodeSnippet snippet) async {
    final updated = snippet.copyWith(isFavorite: !snippet.isFavorite);
    await _ref.read(snippetsRepositoryProvider).updateSnippet(_uid, updated);
  }

  Future<void> deleteSnippet(String snippetId) async {
    await _ref.read(snippetsRepositoryProvider).deleteSnippet(_uid, snippetId);
  }
}