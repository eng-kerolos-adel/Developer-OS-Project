import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/developer_profile.dart';
import '../data/repositories/profile_repository.dart';
import '../../auth/providers/auth_provider.dart';

final profileProvider = StreamProvider<DeveloperProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchProfile(user.uid);
});

final skillsProvider = StreamProvider<List<DeveloperSkill>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchSkills(user.uid);
});

final certificatesProvider = StreamProvider<List<Certificate>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchCertificates(user.uid);
});

final linksProvider = StreamProvider<List<DeveloperLink>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchLinks(user.uid);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repo;
  final String uid;

  ProfileController(this._repo, this.uid) : super(const AsyncValue.data(null));

  Future<void> saveProfile(DeveloperProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.saveProfile(profile));
  }

  Future<void> addSkill(DeveloperSkill skill) async {
    await _repo.addSkill(uid, skill);
  }

  Future<void> deleteSkill(String skillId) async {
    await _repo.deleteSkill(uid, skillId);
  }

  Future<void> addCertificate(Certificate cert) async {
    await _repo.addCertificate(uid, cert);
  }

  Future<void> deleteCertificate(String certId) async {
    await _repo.deleteCertificate(uid, certId);
  }

  Future<void> saveLink(DeveloperLink link) async {
    await _repo.saveLink(uid, link);
  }

  Future<void> deleteLink(String linkId) async {
    await _repo.deleteLink(uid, linkId);
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileController(repo, user?.uid ?? '');
});
