import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io'; // For File
import 'package:path_provider/path_provider.dart'; // For path_provider
import 'package:share_plus/share_plus.dart'; // For sharing files
import 'package:file_picker/file_picker.dart'; // For file picking
import 'goal.dart';
import 'goal_card.dart';
import 'goal_detail_page.dart';
import 'add_goal_dialog.dart';

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

  List<Goal> getFilteredGoals() {
    if (selectedColors.isEmpty) return goals;
    return goals.where((goal) => selectedColors.contains(goal.color)).toList();
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
              // TextButton(
              //   onPressed: () {
              //     setState(() {
              //       goals.addAll(jsonData.map((goalJson) => Goal.fromJson(goalJson)));
              //     });
              //     _saveGoals();
              //     Navigator.pop(context);
              //   },
              //   child: const Text('Add'),
              // ),
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
    List<Color> goalColors = goals.map((goal) => goal.color).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Life Goals'),
            Row(
              children: goalColors.map((color) {
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
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
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
        children: List.generate(getFilteredGoals().length, (index) {
          Goal goal = getFilteredGoals()[index];
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
            onPressed: () => showAddGoalDialog(context, addGoal),
            child: Icon(Icons.add),
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
