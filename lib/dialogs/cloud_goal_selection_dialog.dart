import 'package:flutter/material.dart';

class GoalSelectionDialog extends StatefulWidget {
  final List<String> goalNames; // Add this line

  GoalSelectionDialog({required this.goalNames}); // Modify constructor

  @override
  _GoalSelectionDialogState createState() => _GoalSelectionDialogState();
}

class _GoalSelectionDialogState extends State<GoalSelectionDialog> {
  Set<String> selectedGoals = {};

  // Function to select all goals
  void selectAllGoals() {
    setState(() {
      selectedGoals = Set.from(widget.goalNames); // Select all goals
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cloud Goals'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.goalNames.map((goalName) {
            return CheckboxListTile(
              title: Text(goalName),
              value: selectedGoals.contains(goalName),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedGoals.add(goalName);
                  } else {
                    selectedGoals.remove(goalName);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Handle cancel action here
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Handle import all action here
            Navigator.of(context).pop(selectedGoals.toList());
            selectAllGoals();  // Select all goals
          },
          child: Text('Select All'),
        ),
        TextButton(
          onPressed: () {
            // Handle import action here
            Navigator.of(context).pop(selectedGoals.toList());
          },
          child: Text('Import'),
        ),

      ],
    );
  }
}
