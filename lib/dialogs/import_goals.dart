import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../goal.dart';

Future<void> importGoals(BuildContext context, void Function(List<Goal>) addGoalsCallback) async {
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);

  if (result != null) {
    File file = File(result.files.single.path!);
    String fileContent = await file.readAsString();

    // Parse JSON and show a dialog with checkboxes for goals
    List<dynamic> jsonData = jsonDecode(fileContent);
    List<Goal> importedGoals = jsonData.map((goalJson) => Goal.fromJson(goalJson)).toList();

    // Keep track of selected goals
    List<Goal> selectedGoals = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Import Goals'),
              content: SingleChildScrollView(
                child: Column(
                  children: importedGoals.map((goal) {
                    return CheckboxListTile(
                      title: Text(goal.name),
                      subtitle: Text(goal.lastUpdated.toIso8601String()),
                      value: selectedGoals.contains(goal),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedGoals.add(goal);
                          } else {
                            selectedGoals.remove(goal);
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
                    addGoalsCallback(importedGoals);
                    Navigator.pop(context);
                  },
                  child: const Text('Import All'),
                ),
                TextButton(
                  onPressed: () {
                    addGoalsCallback(selectedGoals);
                    // Add selected goals only
                    // setState(() {
                    //   goals.addAll(selectedGoals);
                    // });
                    Navigator.pop(context);
                  },
                  child: const Text('Add Selected'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}