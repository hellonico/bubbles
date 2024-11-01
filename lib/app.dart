import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'goal.dart';

class AppSettings extends ChangeNotifier {
  bool showStarredTasks = false;
  bool showNonCompletedTasks = false;

  AppSettings() {
    _loadSettings();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    showStarredTasks = prefs.getBool('showStarredTasks') ?? false;
    showNonCompletedTasks = prefs.getBool('showNonCompletedTasks') ?? false;
    notifyListeners();
  }

  Future<List<Goal>> loadGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? goalsData = prefs.getString('goals');
    if (goalsData != null) {
      List<dynamic> jsonData = jsonDecode(goalsData);
      List<Goal> _goals = jsonData.map((goalJson) => Goal.fromJson(goalJson)).toList();
      // setState(() {
      //   goals = _goals;
      // });
      return _goals;
    } else {
      return List<Goal>.of([]);
    }
  }

  void toggleShowStarredTasks() async {
    showStarredTasks = !showStarredTasks;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('showStarredTasks', showStarredTasks);
    notifyListeners(); // Notify listeners when the value changes
  }

  void toggleShowNonCompletedTasks() async {
    showNonCompletedTasks = !showNonCompletedTasks;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('showNonCompletedTasks', showNonCompletedTasks);
    notifyListeners();
  }
}