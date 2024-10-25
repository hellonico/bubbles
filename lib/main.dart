import 'dart:convert';
import 'dart:io'; // For File

import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // For sharing files
import 'package:shared_preferences/shared_preferences.dart';

import 'add_goal_dialog.dart';
import 'goal.dart';
import 'goal_card.dart';
import 'goal_detail_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Goals App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Goal> goals = [];
  Set<Color> selectedColors = {};
  bool showImportExportButtons = false; // Initially hide Import/Export buttons
  bool showCompletedGoals = false;  // Hide completed goals by default

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? goalsData = prefs.getString('goals');
    if (goalsData != null) {
      List<dynamic> jsonData = jsonDecode(goalsData);
      setState(() {
        goals = jsonData.map((goalJson) => Goal.fromJson(goalJson)).toList();
      });
    }
  }

  Future<void> _saveGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(goals.map((goal) => goal.toJson()).toList());
    await prefs.setString('goals', jsonData);
  }

  void addGoal(String name, Color color) {
    setState(() {
      goals.add(Goal(name: name, color: color, tasks: []));
    });
    _saveGoals();
  }

  void editGoal(Goal goal, String newName, Color newColor) {
    setState(() {
      goal.name = newName;
      goal.color = newColor;
    });
    _saveGoals();
  }

  void deleteGoal(Goal goal) {
    setState(() {
      goals.remove(goal);
    });
    _saveGoals();
  }

  void refreshGoals() {
    setState(() {});
    _saveGoals();
  }

  // List<Goal> getFilteredGoals() {
  //   if (selectedColors.isEmpty) return goals;
  //   return goals.where((goal) => selectedColors.contains(goal.color)).toList();
  // }
  List<Goal> getFilteredGoals() {
    List<Goal> filteredGoals = selectedColors.isEmpty ? goals : goals.where((goal) => selectedColors.contains(goal.color)).toList();

    // Hide completed goals if 'showCompletedGoals' is false
    if (!showCompletedGoals) {
      filteredGoals = filteredGoals.where((goal) => !isGoalCompleted(goal)).toList();
    }

    return filteredGoals;
  }

  bool isGoalCompleted(Goal goal) {
    if (goal.tasks.isEmpty) return false; // A goal with no tasks is not considered completed
    return goal.tasks.every((task) => task.isCompleted); // All tasks must be completed
  }

  Future<void> exportGoals() async {
    String jsonData = jsonEncode(goals.map((goal) => goal.toJson()).toList());
    Share.share(jsonData, subject: 'Check out my life goals!');
  }

  Future<void> importGoals() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['txt','json']);

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileContent = await file.readAsString();

      // Parse JSON and show a dialog for replacing or adding
      List<dynamic> jsonData = jsonDecode(fileContent);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Import Goals'),
            content: const Text('Do you want to replace current goals or add them?'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    goals = jsonData.map((goalJson) => Goal.fromJson(goalJson)).toList();
                  });
                  _saveGoals();
                  Navigator.pop(context);
                },
                child: const Text('Replace'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the filtered goals based on selected colors and the 'showCompletedGoals' flag
    List<Goal> filteredGoals = getFilteredGoals();

    // Only include the colors of the visible goals after filtering
    List<Color> visibleGoalColors = filteredGoals.map((goal) => goal.color).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Life Goals'),
            Row(
              // Only show color icons for colors that are present in the filtered (visible) goals
              children: visibleGoalColors.map((color) {
                bool isSelected = selectedColors.contains(color);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedColors.remove(color);
                      } else {
                        selectedColors.add(color);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      body: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final goal = goals.removeAt(oldIndex);
            goals.insert(newIndex, goal);
          });
          _saveGoals();
        },
        children: List.generate(filteredGoals.length, (index) {
          Goal goal = filteredGoals[index];
          return GestureDetector(
            key: ValueKey(goal.name),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailPage(
                  goal: goal,
                  refreshGoals: refreshGoals,
                ),
              ),
            ),
            child: GoalCard(
              goal: goal,
              onEditGoal: (newName, newColor) => editGoal(goal, newName, newColor),
              onDeleteGoal: () => deleteGoal(goal),
            ),
          );
        }),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showImportExportButtons) ...[
            FloatingActionButton(
              onPressed: () => importGoals(),
              child: Icon(Icons.download),
              tooltip: 'Import Goals',
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: () => exportGoals(),
              child: Icon(Icons.upload_file),
              tooltip: 'Export Goals',
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  showCompletedGoals = !showCompletedGoals;
                });
              },
              child: Icon(showCompletedGoals ? Icons.visibility_off : Icons.visibility),
              tooltip: showCompletedGoals ? 'Hide Completed Goals' : 'Show Completed Goals',
            ),
            SizedBox(height: 16), // Space between buttons
          ],
          FloatingActionButton(
            onPressed: () => showAddGoalDialog(context, addGoal),
            child: GestureDetector(
              onLongPress: () {
                setState(() {
                  showImportExportButtons = !showImportExportButtons;
                });
              },
              child: Icon(Icons.add),
            ),
            tooltip: 'Add Goal',
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
