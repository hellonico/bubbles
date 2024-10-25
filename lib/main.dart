import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding and decoding
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
  Set<Color> selectedColors = {}; // Set to keep track of selected colors

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // Load goals from SharedPreferences
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

  // Save goals to SharedPreferences
  Future<void> _saveGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(goals.map((goal) => goal.toJson()).toList());
    await prefs.setString('goals', jsonData);
  }

  void addGoal(String name, Color color) {
    setState(() {
      goals.add(Goal(name: name, color: color, tasks: []));
    });
    _saveGoals(); // Save goals after adding
  }

  void editGoal(Goal goal, String newName, Color newColor) {
    setState(() {
      goal.name = newName;
      goal.color = newColor;
    });
    _saveGoals(); // Call save function to persist changes
  }

  void deleteGoal(Goal goal) {
    setState(() {
      goals.remove(goal); // Remove the goal from the list
    });
    _saveGoals();
  }

  void refreshGoals() {
    setState(() {});
    _saveGoals(); // Save goals after refreshing
  }

  // Filter goals based on selected colors
  List<Goal> getFilteredGoals() {
    if (selectedColors.isEmpty) return goals;
    return goals.where((goal) => selectedColors.contains(goal.color)).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Color> goalColors = goals.map((goal) => goal.color).toSet().toList(); // Extract unique colors

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
                      // Toggle color selection
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
          _saveGoals(); // Save goals after reordering
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
                  refreshGoals: refreshGoals, // Passing refresh callback
                ),
              ),
            ),
            child: GoalCard(
              goal: goal,
              onEditGoal: (newName, newColor) => editGoal(goal, newName, newColor), // Edit goal callback
              onDeleteGoal: () => deleteGoal(goal), // Delete goal callback
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddGoalDialog(context, addGoal),
        child: Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
