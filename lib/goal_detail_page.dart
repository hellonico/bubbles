import 'package:bubbles/task_timer_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_task_dialog.dart';
import 'edit_task_page.dart';
import 'goal.dart';
import 'mardown_view_page.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;
  final VoidCallback refreshGoals;

  GoalDetailPage({required this.goal, required this.refreshGoals});

  @override
  _GoalDetailPageState createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  bool showStarredTasks = false; // State for showing starred tasks
  bool showCompletedTasks = true; // State for showing completed tasks

  void addTask(String taskName) {
    setState(() {
      widget.goal.tasks.add(Task(title: taskName));
    });
    widget.refreshGoals();
  }

  void completeTask(Task task, bool? value) {
    setState(() {
      task.isCompleted = value ?? false;
      task.completedAt = value == true ? DateTime.now() : null;
    });
    widget.refreshGoals();
  }

  void toggleStar(Task task) {
    setState(() {
      task.isStarred = !task.isStarred; // Toggle the star status
    });
    widget.refreshGoals();
  }

  Future<void> deleteTask(Task task) async {
    bool shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    ) ?? false;

    if (shouldDelete) {
      setState(() {
        widget.goal.tasks.remove(task);
      });
      widget.refreshGoals();
    }
  }

  void editTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTaskPage(
          task: task,
          onSave: (updatedDescription) {
            setState(() {
              task.description = updatedDescription;
            });
            _saveTaskToLocal(task);
            widget.refreshGoals();
          },
        ),
      ),
    );
  }

  Future<void> _saveTaskToLocal(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(task.title, task.description ?? '');
    widget.refreshGoals();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.goal.name),
          actions: [
            // Markdown icon to open the MarkdownViewPage
            IconButton(
              icon: Icon(Icons.description), // Icon for markdown
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MarkdownViewPage(goal: widget.goal),
                  ),
                );
              },
            ),
            // Star icon to toggle starred tasks
            IconButton(
              icon: Icon(
                showStarredTasks ? Icons.star : Icons.star_border,
                color: showStarredTasks ? Colors.yellow : Colors.black, // Yellow when active
              ),
              onPressed: () {
                setState(() {
                  showStarredTasks = !showStarredTasks; // Toggle starred tasks visibility
                });
              },
            ),
            // Completed tasks icon to toggle completed tasks
            IconButton(
              icon: Icon(
                showCompletedTasks ? Icons.check_circle_outline_rounded : Icons.check_circle_outline_outlined, // Show or hide completed tasks
                color: Colors.black,
                fill: 1.0,
              ),
              onPressed: () {
                setState(() {
                  showCompletedTasks = !showCompletedTasks; // Toggle completed tasks visibility
                });
              },
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: widget.goal.tasks.length,
          itemBuilder: (context, index) {
            Task task = widget.goal.tasks[index];

            // Filter based on starred and completed tasks
            if (showStarredTasks && !task.isStarred) return Container();
            if (!showCompletedTasks && task.isCompleted) return Container();

            return Container(
              color: task.isCompleted ? widget.goal.color : Colors.transparent, // Color based on completion
              child: Dismissible(
                key: Key(task.title), // Unique key for each task
                background: Container(
                  color: Colors.blue, // Edit background color
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(Icons.edit, color: Colors.white), // Edit icon
                ),
                secondaryBackground: Container(
                  color: Colors.red, // Delete background color
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white), // Delete icon
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await deleteTask(task); // Delete task logic
                    return false; // Prevent dismissal
                  } else if (direction == DismissDirection.startToEnd) {
                    editTask(task); // Edit task logic
                    return false; // Prevent dismissal
                  }
                  return false;
                },
                child: GestureDetector(
                  onTap: () {
                    startTimer(task); // Timer logic
                  },
                  child: ListTile(
                    title: RichText(
                      text: TextSpan(
                        children: _buildTextSpan(task.title),
                      ),
                    ),
                    subtitle: task.description != null
                        ? Text(task.description!.split('\n').first)
                        : null, // Show first line of description
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Star icon for each task
                        IconButton(
                          icon: Icon(
                            task.isStarred ? Icons.star : Icons.star_border, // Show starred or empty star
                            color: task.isStarred ? Colors.yellow : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              task.isStarred = !task.isStarred; // Toggle star status
                            });
                            widget.refreshGoals(); // Refresh the goal list
                          },
                        ),
                        // Checkbox for completion
                        Checkbox(
                          value: task.isCompleted,
                          onChanged: (bool? value) {
                            completeTask(task, value); // Complete task logic
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddTaskDialog(context, addTask), // Add task logic
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpan(String text) {
    final RegExp urlRegex = RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)');
    List<TextSpan> spans = [];
    text.split(' ').forEach((word) {
      if (urlRegex.hasMatch(word)) {
        spans.add(TextSpan(
          text: word + ' ',
          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _launchURL(word);
            },
        ));
      } else {
        spans.add(TextSpan(style: TextStyle(color: Colors.black), text: word + ' '));
      }
    });
    return spans;
  }

  void startTimer(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskTimerPage(
          taskName: task.title,
          onComplete: () {
            completeTask(task, true);
            Navigator.of(context).pop();
          },
          onLater: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    // Launch URL code here
  }
}
