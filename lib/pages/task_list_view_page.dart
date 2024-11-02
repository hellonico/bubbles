import 'package:flutter/material.dart';

import '../goal.dart';
import '../mongodb_service.dart';
import 'edit_task_page.dart';
import 'mardown_view_page.dart';

class TaskListView extends StatefulWidget {
  final List<Goal> goals;

  const TaskListView({
    Key? key,
    required List<Goal> this.goals,
  }) : super(key: key);

  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  // final List<Goal> goals;

  // _TaskListViewState({required this.goals});

  bool showCompletedTasks = false; // Controls the completed tasks display
  bool filterStarredTasks = false; // Toggle for starred tasks

  @override
  Widget build(BuildContext context) {
    final uniqueColors = widget.goals
        .map((goal) => goal.color)
        .toSet()
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              // Display color squares for each goal
              ...uniqueColors.map((color) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                width: 20.0,
                height: 20.0,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.rectangle,
                ),
              )),
              Spacer(), // Push the toggle icon to the end of the AppBar
              IconButton(
                icon: Icon(
                  showCompletedTasks ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    showCompletedTasks = !showCompletedTasks;
                  });
                },
                tooltip: showCompletedTasks ? 'Hide Completed Tasks' : 'Show Completed Tasks',
              ),
              IconButton(
                icon: Icon(
                  filterStarredTasks ? Icons.star : Icons.star_border,
                  color: filterStarredTasks ? Colors.amber : null,
                ),
                onPressed: () {
                  setState(() {
                    filterStarredTasks = !filterStarredTasks;
                  });
                },
                tooltip: filterStarredTasks ? 'Show All Tasks' : 'Show Starred Tasks Only',
              ),
            ],
          ),
        ),
        body: ListView(
            children: widget.goals
                .map((goal) =>
                goal.tasks
                    .where((task) =>
                    (showCompletedTasks || !task.isCompleted) && // Filter by completed status
                    (!filterStarredTasks || task.isStarred))     // Filter by starred status
                    .map((task) =>
                    ListTile(
                      title: Text(task.title,style: TextStyle(
                        color: task.isCompleted ? Colors.grey : Colors.black, // Set color for completed tasks
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),),
                      subtitle: Text(goal.name, style:TextStyle(
                        color: task.isCompleted ? Colors.grey : Colors.black, // Set color for completed tasks
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      )), // Display goal name
                      leading: Container(
                        width: 10.0,
                        height: 10.0,
                        decoration: BoxDecoration(
                          color: goal.color,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      trailing: task.isStarred
                          ? Icon(Icons.star, color: Colors.amber)
                          : null, // Show star icon if task is starred
                      onTap: () {
                        Navigator.of(context).push(
                          materialPageRoute(goal, task),
                        );
                      },
                    )))
                .expand((taskTile) => taskTile) // Flatten the list of lists
                .toList()));
  }

  MaterialPageRoute<dynamic> materialPageRoute(Goal goal, Task task) {
    return MaterialPageRoute(
      builder: (context) => EditTaskPage(
        goal: goal,
        task: task,
        onSave: (newDescription) {
          if (goal.isSynchronized) {
            MongoDBService.saveGoalToMongoDB(goal);
          }
        },
        onGoalChange: (task, goal) {},
        onNameChange: (newName) {
          if (goal.isSynchronized) {
            MongoDBService.saveGoalToMongoDB(goal);
          }
        },
      ),
    );
  }
}