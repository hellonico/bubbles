import 'package:flutter/material.dart';
import 'goal.dart';
import 'add_task_dialog.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  final VoidCallback refreshGoals; // Callback to refresh the main page

  GoalDetailPage({required this.goal, required this.refreshGoals});

  @override
  _GoalDetailPageState createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  void addTask(String taskName) {
    setState(() {
      widget.goal.tasks.add(Task(title: taskName));
    });
  }

  void completeTask(Task task, bool? value) {
    setState(() {
      task.isCompleted = value ?? false;
      task.completedAt = value == true ? DateTime.now() : null;
    });

    // Refresh the main page to reflect the new progress
    widget.refreshGoals();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe right to left to go back
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.goal.name)),
        body: ListView.builder(
          itemCount: widget.goal.tasks.length,
          itemBuilder: (context, index) {
            Task task = widget.goal.tasks[index];
            return ListTile(
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: task.isCompleted && task.completedAt != null
                  ? Text('Completed on: ${task.completedAt}')
                  : null,
              trailing: Checkbox(
                value: task.isCompleted,
                onChanged: (bool? value) {
                  completeTask(task, value);
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddTaskDialog(context, addTask),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
