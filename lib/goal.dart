import 'package:flutter/material.dart';
class Task {
  String title;
  bool isCompleted;
  DateTime? completedAt;
  var description;
  bool isStarred; // New property to indicate if a task is starred

  Task({
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.description,
    this.isStarred = false, // Default is not starred
  });

  // Convert Task to JSON
  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'description': description,
    'isStarred': isStarred, // Add isStarred to JSON
  };

  // Create Task from JSON
  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      description: json['description'],
      isStarred: json['isStarred'] ?? false, // Default to false if not present
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

class Goal {
  String name;
  Color color;
  List<Task> tasks;

  Goal({required this.name, required this.color, required this.tasks});

  double getProgress() {
    if (tasks.isEmpty) return 0.0; // No tasks mean no progress
    int completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color.value,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      name: json['name'],
      color: Color(json['color']),
      tasks: (json['tasks'] as List).map((taskJson) => Task.fromJson(taskJson)).toList(),
    );
  }
}
