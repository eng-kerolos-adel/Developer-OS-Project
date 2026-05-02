import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:developer_os/features/projects/domain/models/project.dart';
import 'package:developer_os/core/constants/app_constants.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(firestore: FirebaseFirestore.instance);
});

class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Stream<List<Project>> watchProjects(String uid) {
    return _firestore
        .collection(AppConstants.projectsCollection)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Project.fromMap(d.data(), d.id)).toList());
  }

  Future<Project?> getProject(String id) async {
    final doc =
        await _firestore.collection(AppConstants.projectsCollection).doc(id).get();
    if (!doc.exists) return null;
    return Project.fromMap(doc.data()!, doc.id);
  }

  Future<String> createProject(Project project) async {
    final ref =
        await _firestore.collection(AppConstants.projectsCollection).add(project.toMap());
    return ref.id;
  }

  Future<void> updateProject(Project project) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(project.id)
        .update(project.toMap());
  }

  Future<void> deleteProject(String id) async {
    await _firestore.collection(AppConstants.projectsCollection).doc(id).delete();
  }

  // Tasks
  Stream<List<ProjectTask>> watchTasks(String projectId) {
    return _firestore
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .collection(AppConstants.tasksCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ProjectTask.fromMap(d.data(), d.id)).toList());
  }

  Future<String> createTask(ProjectTask task) async {
    final ref = await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(task.projectId)
        .collection(AppConstants.tasksCollection)
        .add(task.toMap());
    return ref.id;
  }

  Future<void> updateTask(ProjectTask task) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(task.projectId)
        .collection(AppConstants.tasksCollection)
        .doc(task.id)
        .update(task.toMap());
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _firestore
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .collection(AppConstants.tasksCollection)
        .doc(taskId)
        .delete();
  }

  // جيب المشاريع مرة واحدة (مش stream) — للاستخدام في import
  Future<List<Project>> getProjectsOnce(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.projectsCollection)
        .where('uid', isEqualTo: uid)
        .get();
    return snap.docs.map((d) => Project.fromMap(d.data(), d.id)).toList();
  }
}