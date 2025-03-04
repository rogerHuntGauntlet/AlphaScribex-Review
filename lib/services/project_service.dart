import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/writing_project.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _projectsCollection = 'writing_projects';

  // Create a new project
  Future<WritingProject> createProject({
    required String title,
    required String description,
    required String type,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final projectData = {
      'userId': user.uid,
      'title': title,
      'description': description,
      'type': type,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'wordCount': 0,
      'isCompleted': false,
    };

    final docRef = await _firestore.collection(_projectsCollection).add(projectData);
    
    return WritingProject(
      id: docRef.id,
      userId: user.uid,
      title: title,
      description: description,
      type: type,
      createdAt: now,
      updatedAt: now,
      wordCount: 0,
      isCompleted: false,
    );
  }

  // Get user's projects
  Stream<List<WritingProject>> getUserProjects() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection(_projectsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WritingProject.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Get most recent project
  Future<WritingProject?> getMostRecentProject() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final querySnapshot = await _firestore
        .collection(_projectsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    return WritingProject.fromMap({
      'id': doc.id,
      ...doc.data(),
    });
  }
} 