import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  bool showStarredTasks = false;
  bool showNonCompletedTasks = false;

  void toggleShowStarredTasks() {
    showStarredTasks = !showStarredTasks;
    notifyListeners(); // Notify listeners when the value changes
  }

  void toggleShowNonCompletedTasks() {
    showNonCompletedTasks = !showNonCompletedTasks;
    notifyListeners();
  }
}