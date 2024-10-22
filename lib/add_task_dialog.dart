import 'package:flutter/material.dart';

void showAddTaskDialog(BuildContext context, Function(String) addTask) {
  String taskName = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Add New Task'),
        content: TextField(
          decoration: InputDecoration(labelText: 'Task Name'),
          onChanged: (value) {
            taskName = value;
          },
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              if (taskName.isNotEmpty) {
                addTask(taskName);
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  );
}
