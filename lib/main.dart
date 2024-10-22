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
      title: 'Goals App',
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
  }

  void deleteGoal(Goal goal) {
    setState(() {
      goals.remove(goal); // Remove the goal from the list
    });
  }

  void refreshGoals() {
    setState(() {});
    _saveGoals(); // Save goals after refreshing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Goals')),
      body: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final goal = goals.removeAt(oldIndex);
            goals.insert(newIndex, goal);
          });
          _saveGoals(); // Save goals after reordering
        },
        children: List.generate(goals.length, (index) {
          Goal goal = goals[index];
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
              )

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
