import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/writing_project.dart';

class WritingProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'writing_projects';

  // Create a new writing project
  Future<WritingProject> createProject({
    required String userId,
    required String title,
    required String projectType,
    DateTime? deadline,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'userId': userId,
      'title': title,
      'projectType': projectType,
      'deadline': deadline,
      'status': 'in_progress',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create initial version
    await _firestore.collection('project_versions').add({
      'projectId': docRef.id,
      'content': [],
      'versionNumber': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return WritingProject.fromMap({...doc.data()!, 'id': doc.id});
  }

  // Get all projects for a user
  Stream<List<WritingProject>> getUserProjects(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WritingProject.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get a single project
  Stream<WritingProject> getProject(String projectId) {
    return _firestore
        .collection(_collection)
        .doc(projectId)
        .snapshots()
        .map((doc) => WritingProject.fromMap(doc.data()!));
  }

  // Update project content with autosave
  Future<void> updateContent({
    required String projectId,
    required String content,
  }) async {
    await _firestore.collection(_collection).doc(projectId).update({
      'content': content,
      'updatedAt': DateTime.now(),
    });
  }

  // Update project status
  Future<void> updateStatus({
    required String projectId,
    required String status,
  }) async {
    await _firestore.collection(_collection).doc(projectId).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    // Delete all versions
    final versionsQuery = await _firestore
        .collection('project_versions')
        .where('projectId', isEqualTo: projectId)
        .get();
    
    for (var doc in versionsQuery.docs) {
      await doc.reference.delete();
    }

    // Delete project
    await _firestore.collection(_collection).doc(projectId).delete();
  }

  // Create a version history entry
  Future<void> createVersion({
    required String projectId,
    required String content,
    required int versionNumber,
  }) async {
    final docRef = _firestore
        .collection(_collection)
        .doc(projectId)
        .collection('versions')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'content': content,
      'versionNumber': versionNumber,
      'createdAt': DateTime.now(),
    });
  }

  // Get version history for a project
  Stream<List<Map<String, dynamic>>> getVersionHistory(String projectId) {
    return _firestore
        .collection(_collection)
        .doc(projectId)
        .collection('versions')
        .orderBy('versionNumber', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  Future<String?> getProjectContent(String projectId) async {
    final latestVersion = await _firestore
        .collection('project_versions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    if (latestVersion.docs.isEmpty) return null;
    
    final content = latestVersion.docs.first.data()['content'] as String? ?? '';
    
    // Update word count
    final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
    await _firestore.collection(_collection).doc(projectId).update({
      'wordCount': wordCount,
    });
    
    return content;
  }

  Future<List<Map<String, dynamic>>> getProjectVersions(String projectId) async {
    final versions = await _firestore
        .collection('project_versions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('versionNumber', descending: true)
        .get();

    return versions.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  Future<void> saveProjectContent(String projectId, String content) async {
    // Calculate word count
    final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

    // Get the latest version number
    final latestVersion = await _firestore
        .collection('project_versions')
        .where('projectId', isEqualTo: projectId)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    final newVersionNumber = latestVersion.docs.isEmpty
        ? 1
        : latestVersion.docs.first.data()['versionNumber'] + 1;

    // Create new version
    await _firestore.collection('project_versions').add({
      'projectId': projectId,
      'content': content,
      'versionNumber': newVersionNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update project with new word count
    await _firestore.collection(_collection).doc(projectId).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'wordCount': wordCount,
    });
  }

  Future<void> saveAnalysisResults(String projectId, Map<String, dynamic> results) async {
    await _firestore.collection(_collection).doc(projectId).update({
      'lastAnalysis': {
        ...results,
        'analyzedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getAnalysisResults(String projectId) async {
    final doc = await _firestore.collection(_collection).doc(projectId).get();
    final data = doc.data();
    if (data != null && data.containsKey('lastAnalysis')) {
      return data['lastAnalysis'] as Map<String, dynamic>;
    }
    return null;
  }
} 