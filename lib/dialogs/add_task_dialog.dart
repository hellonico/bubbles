import 'package:flutter/material.dart';

void showAddTaskDialog(BuildContext context, Function(String, bool) addTask) {
  String taskName = '';
  bool isStarred = false;

  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(children: [
                Text('Add New Task'),
                IconButton(
                  icon: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: isStarred ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      isStarred = !isStarred;
                    });
                  },
                ),
                // Checkbox for completion
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Task Name'),
                    onChanged: (value) {
                      taskName = value;
                    },
                  ),
                ],
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
                      addTask(taskName, isStarred);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      }
  );
}
