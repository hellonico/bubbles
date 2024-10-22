import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add this import for handling links

import 'add_task_dialog.dart';
import 'goal.dart';

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
        widget.goal.tasks.remove(task); // Remove the task from the list
      });

      // Refresh the main page to reflect the new progress
      widget.refreshGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe right to go back
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.goal.name)),
        body: ListView.builder(
          itemCount: widget.goal.tasks.length,
          itemBuilder: (context, index) {
            Task task = widget.goal.tasks[index];
            return Dismissible(
              key: Key(task.title), // Unique key for each task
              background: Container(
                color: Colors.red, // Background color for swipe left
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white), // Delete icon
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  await deleteTask(task); // Call delete task function
                  return false; // Prevent the card from being dismissed
                }
                return false;
              },
              child: ListTile(
                title: RichText(
                  text: TextSpan(
                    children: _buildTextSpan(task.title),
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

  // Function to build text span and detect links
  List<TextSpan> _buildTextSpan(String text) {
    final RegExp urlRegex = RegExp(
        r'(https?:\/\/[^\s]+)|(www\.[^\s]+)');
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
        spans.add(TextSpan(style: const TextStyle(fontFamily: "Verdana", fontSize: 9, color: Colors.black), text: word + ' '));
      }
    });
    return spans;
  }

  // Function to launch URLs
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    // if (await canLaunch(uri.toString())) {
    //   await launch(uri.toString());
    // } else {
    //   throw 'Could not launch $url';
    // }
  }
}
