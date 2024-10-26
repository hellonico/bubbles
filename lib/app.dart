import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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