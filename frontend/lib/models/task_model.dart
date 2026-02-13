class Task {
  final int id;
  final String title;
  final String? description;
  final String priority;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      isCompleted: json['is_completed'] ?? false,
    );
  }
}