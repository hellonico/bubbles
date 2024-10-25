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
    ) ??
        false;

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
            IconButton(
              icon: Icon(Icons.text_format),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MarkdownViewPage(goal: widget.goal),
                  ),
                );
              },
            ),
          ],
        ),
        body: ReorderableListView(
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final task = widget.goal.tasks.removeAt(oldIndex);
              widget.goal.tasks.insert(newIndex, task);
            });
            widget.refreshGoals(); // Save goals after reordering
          },
          children: List.generate(widget.goal.tasks.length, (index) {
            Task task = widget.goal.tasks[index];
            return Container(
              key: ValueKey(task.title), // Ensure each task has a unique key
              color: task.isCompleted
                  ? widget.goal.color
                  : Colors.transparent, // Set background color based on completion status
              child: Dismissible(
                key: Key(task.title), // Unique key for each task
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20),
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await deleteTask(task);
                    return false;
                  } else if (direction == DismissDirection.startToEnd) {
                    editTask(task);
                    return false;
                  }
                  return false;
                },
                child: GestureDetector(
                  onTap: () {
                    startTimer(task);
                  },
                  child: ListTile(
                    title: RichText(
                      text: TextSpan(
                        children: _buildTextSpan(task.title),
                      ),
                    ),
                    subtitle: task.description != null
                        ? Text(task.description!.split('\n').first)
                        : null,
                    trailing: Checkbox(
                      value: task.isCompleted,
                      onChanged: (bool? value) {
                        completeTask(task, value);
                      },
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => showAddTaskDialog(context, addTask),
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
          style: TextStyle(
              color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _launchURL(word);
            },
        ));
      } else {
        spans.add(
            TextSpan(style: TextStyle(color: Colors.black), text: word + ' '));
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
    // if (await canLaunch(uri.toString())) {
    //   await launch(uri.toString());
    // } else {
    //   throw 'Could not launch $url';
    // }
  }
}
