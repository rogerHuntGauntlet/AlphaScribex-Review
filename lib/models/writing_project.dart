import 'package:cloud_firestore/cloud_firestore.dart';

class WritingProject {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int wordCount;
  final bool isCompleted;
  final Map<String, dynamic>? lastAnalysis;

  WritingProject({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.wordCount,
    required this.isCompleted,
    this.lastAnalysis,
  });

  factory WritingProject.fromMap(Map<String, dynamic> map) {
    return WritingProject(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      wordCount: map['wordCount'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      lastAnalysis: map['lastAnalysis'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'wordCount': wordCount,
      'isCompleted': isCompleted,
      'lastAnalysis': lastAnalysis,
    };
  }

  WritingProject copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wordCount,
    bool? isCompleted,
    Map<String, dynamic>? lastAnalysis,
  }) {
    return WritingProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCount: wordCount ?? this.wordCount,
      isCompleted: isCompleted ?? this.isCompleted,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
    );
  }
} 