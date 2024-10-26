import 'package:bubbles/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'goal.dart';

class MongoDBService {
  static const String defaultDbUrl = 'mongodb://default.url:27017/bubbles';
  static const String dbUrlKey = 'mongodb_url';
  static late Db db;
  static late DbCollection collection;

  // Initialize the MongoDB service with a URL stored in preferences or use a default
  static Future<void> init() async {
    String dbUrl = await getMongoDbUrl();
    db = await Db.create(dbUrl);
    await db.open();
    collection = db.collection('bubbles');
  }

  // Getter for the MongoDB URL, which retrieves it from SharedPreferences
  static Future<String> getMongoDbUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(dbUrlKey) ?? defaultDbUrl;
  }

  // Setter for MongoDB URL, which saves it to SharedPreferences
  static Future<void> setMongoDbUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dbUrlKey, url);
    // Optionally, reinitialize the database connection with the new URL
    await init();
  }

// Fetch a single goal by name
  static Future<Map<String, dynamic>?> getGoal(String goalName) async {
    if(!db.isConnected) {
      init();
    }
    var result = await collection.findOne({'goalName': goalName});
    return result;
  }

  // Save (upsert) a goal
  static Future<void> saveGoal(Map<String, dynamic> goalData) async {
    if(!db.isConnected) {
      init();
    }
    await collection.updateOne(
      where.eq('goalName', goalData['goalName']),
      ModifierBuilder()
          .set('tasks', goalData['tasks'])
          .set('color', encodeColorToJson(goalData['color']))
          .set('lastUpdated', DateTime.now().toIso8601String()),
      upsert: true,
    );
  }



  static Future<void> saveGoalToMongoDB(Goal goal) async {
    if(!db.isConnected) {
      init();
    }
    Map<String, dynamic> goalData = {
      'goalName': goal.name,
      'color': encodeColorToJson(goal.color),
      'tasks': goal.tasks.map((task) => task.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await saveGoal(goalData);
  }

  static Future<List<String>> getAllGoalNames() async {
    if(!db.isConnected) {
      init();
    }
    // Fetch distinct goal names from the database
    var goalNames = await collection.distinct('goalName');
    print(goalNames.toString());


    // Ensure goalNames is treated as a list and convert it to List<String>
    // return List<String>.from(goalNames.values as Iterable<String>);
    return List<String>.from(
        goalNames.values.elementAt(0).map((name) => name.toString()));
  }


  // Fetch multiple goals by their names
  static Future<List<Map<String, dynamic>>> getGoalsByNames(
      List<String> goalNames) async {
    if(!db.isConnected) {
      init();
    }
    var goals = await collection.find(where.oneFrom('goalName', goalNames))
        .toList();
    return goals;
  }
}
