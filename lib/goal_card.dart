import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_goal_dialog.dart';
import 'goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final Function(String, Color) onEditGoal; // Callback to edit goal
  final Function() onDeleteGoal; // Callback to delete goal

  const GoalCard({
    Key? key,
    required this.goal,
    required this.onEditGoal,
    required this.onDeleteGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = goal.getProgress(); // Get progress percentage

    // Define colors for the progress
    Color mainColor = goal.color; // Main color
    Color brightColor = mainColor.withOpacity(0.3); // Brighter version for less completed part

    // Calculate flex values for split representation
    int completedFlex = (progress * 100).toInt(); // Completed part
    int remainingFlex = 100 - completedFlex; // Remaining part

    // Get the date of the last completed task, if any
    String? lastCompletedDate;
    for (var task in goal.tasks) {
      if (task.isCompleted && task.completedAt != null) {
        // Use DateFormat to format the date and time (hour)
        lastCompletedDate = DateFormat('yyyy-MM-dd ha').format(task.completedAt!.toLocal());
      }
    }


    return Dismissible(
      key: Key(goal.name),
      background: Container(
        color: Colors.green, // Background color for swipe right
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.edit, color: Colors.white), // Edit icon on swipe right
      ),
      secondaryBackground: Container(
        color: Colors.red, // Background color for swipe left
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white), // Delete icon on swipe left
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to edit
          showEditGoalDialog(context, goal, onEditGoal);
          return false; // Prevent the card from being dismissed
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left to delete
          bool shouldDelete = await showDeleteConfirmationDialog(context);
          if (shouldDelete) {
            onDeleteGoal(); // Trigger goal deletion
            return true; // Allow the card to be dismissed
          } else {
            return false; // Cancel the dismissal
          }
        }
        return false;
      },
      child: Container(
        width: double.infinity,
        height: 80, // Set a height for the goal card
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: mainColor.withOpacity(0.5)), // Optional: border color
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), // Rounded corners for the entire card
          child: Stack(
            children: [
              Row(
                children: [
                  // Left side - Completed part (main color)
                  Expanded(
                    flex: completedFlex,
                    child: Container(
                      color: mainColor,
                    ),
                  ),
                  // Right side - Remaining part (brighter color)
                  Expanded(
                    flex: remainingFlex,
                    child: Container(
                      color: brightColor,
                    ),
                  ),
                ],
              ),
              // Center the goal name and last completed date
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontFamily: "Verdana",
                        color: Colors.black,
                        fontWeight: progress < 1.0 ? FontWeight.bold : FontWeight.normal, // Bold if progress < 100%
                        fontSize: 20,
                      ),
                    ),
                    if (lastCompletedDate != null) // Show last completed date if exists
                      Text(
                        'Last completed: $lastCompletedDate',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show a confirmation dialog before deleting the goal
  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Goal'),
        content: Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false); // Cancel the deletion
            },
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop(true); // Confirm the deletion
            },
          ),
        ],
      ),
    ) ??
        false; // Return false if dialog is dismissed without selecting an option
  }
}

void showEditGoalDialog(
    BuildContext context, Goal goal, Function(String, Color) editGoal) {
  showGoalDialog(
    context: context,
    initialName: goal.name,
    // Provide the current goal name
    initialColor: goal.color,
    // Provide the current color
    onSave: (newName, newColor) {
      editGoal(newName, newColor); // Use the edit callback to update the goal
    },
    isEdit: true, // Indicate that this is an edit action
  );
}
