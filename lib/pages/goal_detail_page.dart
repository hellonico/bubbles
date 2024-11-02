// import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';
import 'dart:async'; // Add this at the top of the file

import 'package:bubbles/pages/task_timer_page.dart';
import 'package:bubbles/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dialogs/add_task_dialog.dart';
import '../app.dart';
import '../goal.dart';
import 'edit_task_page.dart';
import 'mardown_view_page.dart';
import '../mongodb_service.dart';

class GoalDetailPage extends StatefulWidget {
  Goal goal;
  final VoidCallback refreshGoals;

  GoalDetailPage({required this.goal, required this.refreshGoals});

  @override
  _GoalDetailPageState createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  bool isLoading = false;
  Timer? _timer;

  bool isSyncing = false; // Timer for polling

  @override
  void initState() {
    super.initState();
    if (widget.goal.isSynchronized) {
      _syncWithDatabase();
      _startPolling(); // Start polling if synchronized
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the page is closed
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      if (!isSyncing) {
        // Prevent multiple syncs at the same time
        isSyncing = true;
        await syncGoalWithMongoDB(widget.goal); // Check for remote updates
        isSyncing = false;
      }
    });
  }

  // onGoalChange function to update the task's goal
  void _onGoalChange(Task task, Goal newGoal) {
    setState(() {
      // Remove the task from the current goal
      widget.goal.tasks.remove(task);
      syncGoalWithMongoDB(widget.goal);

      // Add the task to the new goal
      newGoal.tasks.add(task);
      syncGoalWithMongoDB(newGoal);

      widget.goal = newGoal;

      widget.refreshGoals();
      // MongoDBService.saveGoalToMongoDB(widget.goal);
      // _syncWithDatabase();
    });
  }

  Future<void> syncGoalWithMongoDB(Goal goal) async {
    await MongoDBService.init();

    // Get the goal data from the remote MongoDB
    Map<String, dynamic>? remoteGoalData =
        await MongoDBService.getGoal(goal.name);

    // printToConsole(goal.lastUpdated.toString());

    if (remoteGoalData != null) {
      DateTime remoteLastUpdated =
          DateTime.parse(remoteGoalData['lastUpdated']);
      DateTime localLastUpdated =
          goal.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(1);
      print('Last update:$localLastUpdated');

      if (remoteLastUpdated.isAfter(localLastUpdated)) {
        // Remote data is newer, update local data
        setState(() {
          goal.tasks = List<Task>.from(remoteGoalData['tasks']
              .map((taskData) => Task.fromJson(taskData)));
          goal.lastUpdated = remoteLastUpdated;
          goal.isSynchronized = true;
          goal.color = decodeColorFromJson(remoteGoalData['color']);
        });
        widget.refreshGoals();
      } else {
        // Local data is newer or the same, upload to MongoDB
        // await saveGoalToMongoDB(goal);
      }
    } else {
      // No remote data, upload local goal to MongoDB
      await MongoDBService.saveGoalToMongoDB(goal);
    }
  }


  // Add this function to handle the sync toggle
  void toggleSync() {
    setState(() {
      widget.goal.isSynchronized = !widget.goal.isSynchronized;
    });

    if (widget.goal.isSynchronized) {
      _syncWithDatabase();
      _startPolling();
    }
  }

  Future<void> _syncWithDatabase() async {
    setState(() {
      isLoading = true;
    });

    // Call function to check sync with MongoDB
    await syncGoalWithMongoDB(widget.goal);

    setState(() {
      isLoading = false;
    });
  }

  void addTask(String taskName, bool isStarred) {
    setState(() {
      widget.goal.tasks.add(Task(title: taskName, isStarred: isStarred));
    });
    widget.refreshGoals();
    if (widget.goal.isSynchronized) {
      MongoDBService.saveGoalToMongoDB(widget.goal);
    }
  }

  void completeTask(Task task, bool? value) {
    setState(() {
      task.isCompleted = value ?? false;
      task.completedAt = value == true ? DateTime.now() : null;
    });
    widget.refreshGoals();
    if (widget.goal.isSynchronized) {
      MongoDBService.saveGoalToMongoDB(widget.goal);
    }
  }

  void toggleStar(Task task) {
    setState(() {
      task.isStarred = !task.isStarred; // Toggle the star status
    });
    widget.refreshGoals();
    if (widget.goal.isSynchronized) {
      MongoDBService.saveGoalToMongoDB(widget.goal);
    }
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
    if (widget.goal.isSynchronized) {
      MongoDBService.saveGoalToMongoDB(widget.goal);
    }
  }

  void editTask(Task task) {
    Navigator.of(context).push(
      materialPageRoute(task),
    );
  }

  MaterialPageRoute<dynamic> materialPageRoute(Task task) {
    return MaterialPageRoute(
      builder: (context) => EditTaskPage(
        goal: widget.goal,
        task: task,
        onSave: (newDescription) {
          setState(() {
            task.description = newDescription; // Update the task description
          });
          if (widget.goal.isSynchronized) {
            MongoDBService.saveGoalToMongoDB(widget.goal);
          }
        },
        onGoalChange: _onGoalChange,
        onNameChange: (newName) {

          setState(() {
            task.title = newName; // Update the task name
          });
          if (widget.goal.isSynchronized) {
            MongoDBService.saveGoalToMongoDB(widget.goal);
          }
        },
      ),
    );
  }

  // TODO: why??
  // Future<void> _saveTaskToLocal(Task task) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(task.title, task.description ?? '');
  //   widget.refreshGoals();
  // }

  void reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final Task task = widget.goal.tasks.removeAt(oldIndex);
      widget.goal.tasks.insert(newIndex, task);
    });
    widget.refreshGoals();
    if (widget.goal.isSynchronized) {
      MongoDBService.saveGoalToMongoDB(widget.goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    bool showStarredTasks = appSettings.showStarredTasks;
    bool showNonCompletedTasks = appSettings.showNonCompletedTasks;

    // List<Task> filteredTasks = widget.goal.tasks.where((task) {
    //   if ((showStarredTasks && !task.isStarred) ||
    //       (showNonCompletedTasks && task.isCompleted)) {
    //     return false;
    //   }
    //   return true; // Include task if it passes the filters
    // }).toList();

    return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.goal.name),
            backgroundColor: widget.goal.color,
            actions: [
              IconButton(
                icon: Icon(
                  widget.goal.isSynchronized ? Icons.sync : Icons.sync_disabled,
                  color: widget.goal.isSynchronized ? Colors.green : Colors.red,
                ),
                onPressed: toggleSync, // Toggle sync state
              ),
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
                  color: showStarredTasks
                      ? Colors.yellow
                      : Colors.black, // Yellow when active
                ),
                onPressed: () {
                  appSettings.toggleShowStarredTasks();
                  // setState(() {
                  //   showStarredTasks = !showStarredTasks; // Toggle starred tasks visibility
                  // });
                },
              ),
              // Completed tasks icon to toggle completed tasks
              IconButton(
                icon: Icon(
                  showNonCompletedTasks
                      ? Icons.check_circle
                      : Icons.check_circle_outline_outlined,
                  // Show or hide completed tasks
                  color: Colors.black,
                ),
                onPressed: () {
                  appSettings.toggleShowNonCompletedTasks();
                  // setState(() {
                  //   showNonCompletedTasks = !showNonCompletedTasks; // Toggle completed tasks visibility
                  // });
                },
              ),
            ],
          ),
          body: isLoading
              ? Center(
                  child:
                      CircularProgressIndicator()) // Show loading when syncing
              : _buildGoalDetail(),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showAddTaskDialog(context, addTask),
            // Add task logic
            child: Icon(Icons.add),
          ),
        ));
  }

  Widget _buildGoalDetail() {
    final appSettings = Provider.of<AppSettings>(context);
    bool showStarredTasks = appSettings.showStarredTasks;
    bool showNonCompletedTasks = appSettings.showNonCompletedTasks;

    List<Task> filteredTasks = widget.goal.tasks.where((task) {
      if ((showStarredTasks && !task.isStarred) ||
          (showNonCompletedTasks && task.isCompleted)) {
        return false;
      }
      return true; // Include task if it passes the filters
    }).toList();

    return ReorderableListView.builder(
        onReorder: reorderTasks,
        // itemCount: widget.goal.tasks.length,
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          // Task task = widget.goal.tasks[index];
          Task task = filteredTasks.elementAt(index);

          // Filter based on starred and completed tasks
          // if (showStarredTasks && !task.isStarred) return Container();
          // if (!showCompletedTasks && task.isCompleted) return Container();
          // already filtered !

          return Container(
              key: ValueKey(task.title), // Unique key for each task
              color: task.isCompleted ? widget.goal.color : Colors.transparent,
              child: Dismissible(
                key: ValueKey(task.title),
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
                  key: ValueKey(task.title),
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
                            task.isStarred ? Icons.star : Icons.star_border,
                            // Show starred or empty star
                            color: task.isStarred ? Colors.yellow : Colors.grey,
                          ),
                          onPressed: () {
                            toggleStar(task); // Toggle star status
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
              ));
        });
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

// Function to launch URLs
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
