import 'category_model.dart';


class Task {
  final int id;
  final String title;
  final String? description;
  final String priority;
  final bool isCompleted;
  final DateTime? deadline;
  final DateTime? updatedAt;
  final int? categoryId;
  final Category? category;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.isCompleted,
    this.deadline,
    this.updatedAt,
    this.categoryId,
    this.category,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      isCompleted: json['is_completed'] ?? false,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      categoryId: json['category_id'],

      category: json['category_rel'] != null
          ? Category.fromJson(json['category_rel'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'is_completed': isCompleted,
      'category': category,
      'deadline': deadline?.toIso8601String(),
      'category_id': categoryId,
    };
  }
}