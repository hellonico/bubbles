import 'package:flutter/material.dart';
import '../goal.dart';
import '../mongodb_service.dart';
import 'edit_task_page.dart';
import 'mardown_view_page.dart';

class TaskListView extends StatefulWidget {
  final List<Goal> goals;

  const TaskListView({
    Key? key,
    required this.goals,
  }) : super(key: key);

  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  bool showCompletedTasks = false;
  bool filterStarredTasks = false;
  String searchText = '';

  // Filters for date ranges
  DateFilter? selectedDateFilter;
  bool showSearchAndDateFilters = false; // Controls the visibility of the search bar and date buttons

  @override
  Widget build(BuildContext context) {
    final uniqueColors = widget.goals.map((goal) => goal.color).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ...uniqueColors.map((color) => Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
              ),
            )),
            Spacer(),
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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            showSearchAndDateFilters = true; // Show the search field and date buttons when refreshed
          });
        },
        child: Column(
          children: [
            // Conditionally display the search bar and date buttons
            if (showSearchAndDateFilters) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0), // More rounded corners
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),
              ),
              // Date filter buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: DateFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0), // Adjust padding for smaller buttons
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: selectedDateFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedDateFilter = filter; // Select this filter
                            showCompletedTasks = true; // Automatically show completed tasks
                          } else {
                            // Deselect filter
                            if (selectedDateFilter == filter) {
                              selectedDateFilter = null; // Clear selected filter
                            }
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
            // Task list
            Expanded(
              child: ListView(
                children: widget.goals.expand((goal) =>
                    goal.tasks.where((task) {
                      // Filter by completed status, starred status, and search text
                      final matchesSearch = task.title.contains(searchText) ||
                          task.description.contains(searchText);
                      final matchesDateFilter = _matchesDateFilter(task);

                      return (showCompletedTasks || !task.isCompleted) &&
                          (!filterStarredTasks || task.isStarred) &&
                          matchesSearch &&
                          (selectedDateFilter == null || matchesDateFilter);
                    }).map((task) {
                      return ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            color: task.isCompleted ? Colors.grey : Colors.black,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          goal.name,
                          style: TextStyle(
                            color: task.isCompleted ? Colors.grey : Colors.black,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        leading: Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: BoxDecoration(
                            color: goal.color,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                        trailing: task.isStarred ? Icon(Icons.star, color: Colors.amber) : null,
                        onTap: () {
                          Navigator.of(context).push(
                            materialPageRoute(goal, task),
                          );
                        },
                      );
                    })).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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

  bool _matchesDateFilter(Task task) {
    if (task.completedAt == null) return false; // If there's no completed date, skip filtering.

    DateTime completedDate = task.completedAt!;
    DateTime now = DateTime.now();

    switch (selectedDateFilter) {
      case DateFilter.today:
        return completedDate.isSameDate(now);
      case DateFilter.yesterday:
        return completedDate.isSameDate(now.subtract(Duration(days: 1)));
      case DateFilter.thisWeek:
        return completedDate.isSameWeek(now);
      case DateFilter.lastWeek:
        return completedDate.isSameWeek(now.subtract(Duration(days: 7)));
      default:
        return false; // Fallback
    }
  }
}

enum DateFilter {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  lastWeek('Last Week');

  final String label;
  const DateFilter(this.label);
}

extension DateTimeExtensions on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isSameWeek(DateTime other) {
    final firstDayOfWeek = other.subtract(Duration(days: other.weekday - 1));
    final lastDayOfWeek = firstDayOfWeek.add(Duration(days: 6));
    return isAfter(firstDayOfWeek) && isBefore(lastDayOfWeek.add(Duration(days: 1))) ||
        isAtSameMomentAs(firstDayOfWeek) || isAtSameMomentAs(lastDayOfWeek);
  }
}
