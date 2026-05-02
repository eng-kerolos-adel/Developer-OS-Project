import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../domain/models/developer_profile.dart';
import '../../../../core/constants/app_constants.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  // Profile
  Stream<DeveloperProfile?> watchProfile(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists
            ? DeveloperProfile.fromMap(doc.data()!, doc.id)
            : null);
  }

  Future<DeveloperProfile?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return DeveloperProfile.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveProfile(DeveloperProfile profile) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<String?> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref().child('profile_photos/$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Skills
  Stream<List<DeveloperSkill>> watchSkills(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.skillsCollection)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DeveloperSkill.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addSkill(String uid, DeveloperSkill skill) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.skillsCollection)
        .doc(skill.id)
        .set(skill.toMap());
  }

  Future<void> deleteSkill(String uid, String skillId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.skillsCollection)
        .doc(skillId)
        .delete();
  }

  // Certificates
  Stream<List<Certificate>> watchCertificates(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.certificatesCollection)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Certificate.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addCertificate(String uid, Certificate cert) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.certificatesCollection)
        .doc(cert.id)
        .set(cert.toMap());
  }

  Future<void> deleteCertificate(String uid, String certId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.certificatesCollection)
        .doc(certId)
        .delete();
  }

  // Links
  Stream<List<DeveloperLink>> watchLinks(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.linksCollection)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DeveloperLink.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveLink(String uid, DeveloperLink link) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.linksCollection)
        .doc(link.id)
        .set(link.toMap());
  }

  Future<void> deleteLink(String uid, String linkId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.linksCollection)
        .doc(linkId)
        .delete();
  }
}
