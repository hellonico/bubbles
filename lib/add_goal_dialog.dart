import 'package:flutter/material.dart';

void showAddGoalDialog(BuildContext context, Function(String, Color) addGoal) {
  showGoalDialog(
    context: context,
    onSave: addGoal, // Use the addGoal function as the save callback
  );
}

void showGoalDialog({
  required BuildContext context,
  String initialName = '',
  Color? initialColor, // Changed to nullable
  required Function(String, Color) onSave,
  bool isEdit = false,
}) {
  // Define the pastel color list as a constant
  const List<Color> pastelColors = [
    Color(0xFFFFC1CC), // Pastel Pink
    Color(0xFFFFD1A4), // Pastel Orange
    Color(0xFFFFF3B0), // Pastel Yellow
    Color(0xFFA7FFEB), // Pastel Mint
    Color(0xFFAECBFA), // Pastel Blue
    Color(0xFFD7B4F3), // Pastel Purple
    Color(0xFFFABAD7), // Pastel Coral
    Color(0xFFFCE4EC), // Pastel Blush
    Color(0xFFE1F5FE), // Pastel Sky Blue
    Color(0xFFD1F5A4), // Pastel Green
    Color(0xFFE8DDFF), // Pastel Lavender
    Color(0xFFFFE3E3), // Pastel Soft Red
    Color(0xFFFFF5D1), // Pastel Soft Yellow
    Color(0xFFCBF0FF), // Pastel Light Cyan
    Color(0xFFFFD7F3), // Pastel Magenta
    Color(0xFFD9EAD3), // Pastel Pale Green
    Color(0xFFFAF2CF), // Pastel Pale Yellow
    Color(0xFFDFDFDF), // Pastel Gray
    Color(0xFFFFF0E1), // Pastel Cream
    Color(0xFFFFE8B6), // Pastel Beige
  ];

  // Set initial color to the first color in the list if not provided
  Color selectedColor = initialColor ?? pastelColors[0];
//  selectedColor = (pastelColors.contains(selectedColor) ? initialColor : pastelColors[0])!;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) { // Wrap in StatefulBuilder to update color
          return AlertDialog(
            title: Text(isEdit ? 'Edit Goal' : 'Add New Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Goal Name'),
                  controller: TextEditingController(text: initialName),
                  onChanged: (value) {
                    initialName = value;
                  },
                ),
                SizedBox(height: 10),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: pastelColors.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Container(
                        width: 100,
                        height: 20,
                        color: color,
                        margin: EdgeInsets.symmetric(vertical: 2),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedColor = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(isEdit ? 'Save' : 'Add'),
                onPressed: () {
                  if (initialName.isNotEmpty) {
                    onSave(initialName, selectedColor);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
