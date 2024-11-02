import 'dart:convert';

import 'package:bubbles/pages/settings_page.dart';
import 'package:bubbles/pages/task_list_view_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // For sharing files
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'dialogs/add_goal_dialog.dart';
import 'dialogs/cloud_goal_selection_dialog.dart';
import 'dialogs/import_goals.dart';
import 'goal.dart';
import 'goal_card.dart';
import 'mongodb_service.dart';
import 'pages/goal_detail_page.dart';
import 'utils/utils.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Goals App',
      theme: ThemeData(
        primarySwatch: Colors.amber,
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
  bool showCompletedGoals = false; // Hide completed goals by default

  @override
  void initState() {
    super.initState();
    MongoDBService.init();
    loadApp();
  }

  void loadApp() async {
    List<Goal> _goals = await AppSettings().loadGoals();
    setState(() {
      goals = _goals;
    });
    await _loadSelectedColors();
  }

  Future<void> _loadSelectedColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _colors = prefs.getString('colors');
    if (_colors != null) {
      List<dynamic> colorStrings = jsonDecode(_colors);
      setState(() {
        selectedColors = colorStrings
            .map((hexString) => decodeColorFromJson(hexString))
            .toSet();
      });
    }
  }

  Future<void> _saveSelectedColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = encodeColorsToJson(selectedColors);
    await prefs.setString('colors', jsonData);
  }

  Future<void> _saveGoalsInSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(goals.map((goal) => goal.toJson()).toList());
    await prefs.setString('goals', jsonData);
  }

  void addGoal(String name, Color color) {
    setState(() {
      goals.add(Goal(
          name: name,
          color: color,
          tasks: [],
          isSynchronized: false,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(0)));
    });
    _saveGoalsInSharedPrefs();
  }

  void editGoal(Goal goal, String newName, Color newColor) {
    setState(() {
      goal.name = newName;
      goal.color = newColor;
    });
    _saveGoalsInSharedPrefs();
    if (goal.isSynchronized) {
      MongoDBService.saveGoalToMongoDB(goal);
    }
  }

  void deleteGoal(Goal goal) {
    setState(() {
      goals.remove(goal);
    });
    _saveGoalsInSharedPrefs();
  }

  void refreshGoals() {
    setState(() {});
    _saveGoalsInSharedPrefs();
  }

  bool isGoalCompleted(Goal goal) {
    if (goal.tasks.isEmpty)
      return false; // A goal with no tasks is not considered completed
    return goal.tasks
        .every((task) => task.isCompleted); // All tasks must be completed
  }

  void debugGoals(List<Goal> goals) {
    for (var goal in goals) {
      bool isCompleted = isGoalCompleted(goal);
      debugPrint(
          'Goal: name=${goal.name}, color=${goal.color}, completed=${isCompleted}');
    }
  }

  List<Color> visibleColors() {
    List<Color> visibleGoalColors = showCompletedGoals
        ? goals
            .map((goal) => goal.color)
            .toSet()
            .toList() // Show all goal colors if completed goals are visible
        : goals
            .where((goal) => !isGoalCompleted(goal))
            .map((goal) => goal.color)
            .toSet()
            .toList(); // Show only non-completed goal colors
    return visibleGoalColors;
  }

  List<Goal> getFilteredGoals() {
    print("--COLORS");
    debugPrint(selectedColors.toString());
    print("--ALL");
    debugGoals(goals);

    List<Goal> filteredGoals = selectedColors.isEmpty
        ? goals
        : goals.where((goal) => selectedColors.contains(goal.color)).toList();

    print("--FILERED");
    debugGoals(filteredGoals);

    // Hide completed goals if 'showCompletedGoals' is false
    if (!showCompletedGoals) {
      filteredGoals =
          filteredGoals.where((goal) => !isGoalCompleted(goal)).toList();
    }
    print("--COMPLETED");
    debugGoals(filteredGoals);
    print("--");

    return filteredGoals;
  }

  Future<void> showExportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Goals'),
          content: Text(
              'Would you like to export all goals or only the displayed goals?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                exportGoals(goals); // Export all goals
              },
              child: Text('All Goals'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                exportGoals(getFilteredGoals()); // Export displayed goals only
              },
              child: Text('Displayed Goals'),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportGoals(List<Goal> goals) async {
    String jsonData = jsonEncode(goals.map((goal) => goal.toJson()).toList());
    Share.share(jsonData, subject: 'Check out my life goals!');
  }

  // Navigation to TaskListView when list is scrolled to the top
  void _navigateToTaskListView() {
    final selectedGoals = getFilteredGoals(); // Selected goals based on color
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListView(goals: selectedGoals),
      ),
    );
  }

  // Future<void> exportGoals() async {
  //   String jsonData = jsonEncode(goals.map((goal) => goal.toJson()).toList());
  //   Share.share(jsonData, subject: 'Check out my life goals!');
  // }

  //
  // Future<void> _syncAllGoals() async {
  //   for (var goal in goals) {
  //     await MongoDBService.saveGoal(goal.toJson()); // Convert each goal to JSON format and save it
  //   }
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('All goals synced to MongoDB')),
  //   );
  // }
  String _currentGoalName = '';
  double _progressValue = 0.0;

  Widget _buildProgressDialog(List<bool> syncStatus) {
    return AlertDialog(
      title: Text('Syncing Goals'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: syncStatus.where((status) => status).length / goals.length,
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200, // Set a fixed height for the ListView
            width: double.infinity, // Ensure it takes up available width
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: syncStatus[index]
                      ? Icon(Icons.check, color: Colors.green)
                      : CircularProgressIndicator(strokeWidth: 2.0),
                  title: Text(goals[index].name),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _syncAllGoals() async {
    List<bool> syncStatus = List.filled(goals.length, false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProgressDialog(syncStatus),
    );

    for (var i = 0; i < goals.length; i++) {
      var goal = goals[i];
      setState(() {
        _currentGoalName = goal.name;
      });

      await MongoDBService.saveGoal(goal.toJson());

      // Update sync status for the current goal
      setState(() {
        syncStatus[i] = true;
      });
    }

    Navigator.pop(context); // Close the dialog after all goals are synced
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All goals synced to MongoDB')),
    );
  }

  // TODO:
  // why do I feel there are two methods ?
  Future<void> _insertGoalLocally(Map<String, dynamic> remoteGoalData) async {
    print(remoteGoalData.toString());
    Goal goal = Goal(
      name: remoteGoalData['goalName'],
      color: remoteGoalData.containsKey('color')
          ? decodeColorFromJson(remoteGoalData['color'])
          : const Color(0xFFBBDEFB),
      // Icy Sky Blue,
      tasks: List<Task>.from(
          remoteGoalData['tasks'].map((taskData) => Task.fromJson(taskData))),
      isSynchronized: true,
      lastUpdated: DateTime.parse(remoteGoalData['lastUpdated']),
    );

    setState(() {
      goals.add(goal);
    });

    // _saveGoalsInSharedPrefs();
  }

  Future<void> _importSelectedGoals(List<String> selectedGoals) async {
    // Fetch the selected goals from MongoDB
    final goals = await MongoDBService.getGoalsByNames(selectedGoals);

    // Insert each goal locally
    for (var goal in goals) {
      await _insertGoalLocally(goal);
    }
    await _saveGoalsInSharedPrefs();
    // refreshGoals();
  }

  Future<void> _fetchGoalNamesFromMongoDB() async {
    // Fetch all goal names from MongoDB via the service
    var goalNames = await MongoDBService.getAllGoalNames();
    // Filter out existing local goals
    final localNames = goals.map((g) => g.name);
    goalNames =
        goalNames.where((goalName) => !localNames.contains(goalName)).toList();
    // Show the multi-selection dialog
    final selectedGoals = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return GoalSelectionDialog(goalNames: goalNames);
      },
    );
    await _importSelectedGoals(selectedGoals!);
  }

  void _cleanGoals() {
    // Log all current goals
    for (var goal in goals) {
      debugPrint(goal.toJson().toString());
    }

    setState(() {
      goals.removeWhere((goal) =>
          goal.name.isEmpty || goal.name == null || goal.color == null);
      selectedColors = {};
    });
  }

// Usage example:
  Future<void> addGoals(List<Goal> goalsToAdd) async {
    setState(() {
      goals.addAll(goalsToAdd);
    });
    await _saveGoalsInSharedPrefs();
  }

  @override
  Widget build(BuildContext context) {
    List<Goal> filteredGoals = getFilteredGoals();
    List<Color> visibleGoalColors =
        visibleColors(); // Show only non-completed goal colors

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Life Goals'),
            Row(
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
                    _saveSelectedColors();
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
      body: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            print("notification");
            if (scrollNotification is ScrollEndNotification &&
                scrollNotification.metrics.pixels ==
                    scrollNotification.metrics.maxScrollExtent) {
              _navigateToTaskListView(); // Navigate when scrolled to top
            }
            return true;
          },
          child: ReorderableListView(
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                // If reordering down, we subtract 1 from the newIndex to account for the "before" position
                if (newIndex > oldIndex) newIndex -= 1;

                // Get the goal being reordered from the filtered list
                final movedGoal = filteredGoals[oldIndex];

                // Find the index of the goal in the original list
                final originalOldIndex = goals.indexOf(movedGoal);

                // If moving up, find the target index in the original list for the newIndex in filtered list
                if (newIndex <= oldIndex) {
                  final newFilteredGoal = filteredGoals[newIndex];
                  final originalNewIndex = goals.indexOf(newFilteredGoal);
                  // Move the goal in the original list
                  goals.removeAt(originalOldIndex);
                  goals.insert(originalNewIndex, movedGoal);
                }
                // If moving down, find the target index in the original list for the newIndex in filtered list
                else {
                  final newFilteredGoal = filteredGoals[newIndex];
                  final originalNewIndex = goals.indexOf(newFilteredGoal) +
                      1; // Insert after in original
                  // Move the goal in the original list
                  goals.removeAt(originalOldIndex);
                  goals.insert(originalNewIndex, movedGoal);
                }
              });
              _saveGoalsInSharedPrefs(); // Save reordered goals
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
                  onEditGoal: (newName, newColor) =>
                      editGoal(goal, newName, newColor),
                  onDeleteGoal: () => deleteGoal(goal),
                ),
              );
            }),
          )),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showImportExportButtons) ...[
            // FloatingActionButton(
            //   onPressed: _loadGoals, // New button
            //   tooltip: 'Refresh',
            //   child: Icon(Icons.refresh), // Icon for the new button
            // ),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
              child: Icon(Icons.settings),
              tooltip: 'Settings',
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: _cleanGoals,
              tooltip: 'Clean Goals',
              child: Icon(Icons.cleaning_services),
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: _syncAllGoals,
              child: Icon(Icons.sync),
              tooltip: 'Sync All Goals',
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: _fetchGoalNamesFromMongoDB, // New button
              tooltip: 'Import Goals',
              child: Icon(Icons.cloud_download), // Icon for the new button
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: () => importGoals(context, addGoals),
              child: Icon(Icons.download),
              tooltip: 'Import Goals',
            ),
            SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              onPressed: () => showExportDialog(context),
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
              child: Icon(
                  showCompletedGoals ? Icons.visibility_off : Icons.visibility),
              tooltip: showCompletedGoals
                  ? 'Hide Completed Goals'
                  : 'Show Completed Goals',
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
  runApp(ChangeNotifierProvider(
    create: (context) => AppSettings(),
    child: MyApp(),
  ));
}
