import 'package:flutter/material.dart';

class ColorPaletteState {
  static String selectedPalette = 'Pastel'; // Default to 'Pastel'
}

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
  // Define the color palettes as constants
  const Map<String, List<Color>> colorPalettes = {
    'Pastel': [
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
    ],
    'Vibrant': [
      Color(0xFFFF0000), // Red
      Color(0xFFFFA500), // Orange
      Color(0xFFFFFF00), // Yellow
      Color(0xFF008000), // Green
      Color(0xFF0000FF), // Blue
      Color(0xFF800080), // Purple
      Color(0xFFFFC0CB), // Pink
      Color(0xFF00FFFF), // Cyan
      Color(0xFFFFD700), // Gold
      Color(0xFFFF4500), // Orange Red
    ],
    'Icy': [
      Color(0xFFE0F7FA), // Icy Blue
      Color(0xFFD1C4E9), // Icy Lavender
      Color(0xFFB2EBF2), // Icy Teal
      Color(0xFFE1BEE7), // Icy Lilac
      Color(0xFFBBDEFB), // Icy Sky Blue
      Color(0xFFB3E5FC), // Icy Light Blue
      Color(0xFFE3F2FD), // Icy Ice Blue
      Color(0xFFBBDEFB), // Icy Soft Blue
      Color(0xFFE0E0E0), // Icy Grey
      Color(0xFFE1F5FE), // Icy Pale Blue
    ],
    'Autumn': [
      Color(0xFFFFB74D), // Autumn Orange
      Color(0xFFFF7043), // Autumn Red
      Color(0xFFFFCA28), // Autumn Yellow
      Color(0xFF8D6E63), // Autumn Brown
      Color(0xFF6D4C41), // Autumn Dark Brown
      Color(0xFF3E2723), // Autumn Deep Brown
      Color(0xFFD7CCC8), // Autumn Light Brown
      Color(0xFFFFAB91), // Autumn Soft Orange
      Color(0xFF6F9EAE), // Autumn Teal
      Color(0xFFE6B0AA), // Autumn Soft Red
    ],
    'Space': [
      Color(0xFF000000), // Very Dark Blue (Black)
      Color(0xFF1A1A2E), // Dark Blue
      Color(0xFF16213E), // Midnight Blue
      Color(0xFF0F3460), // Dark Blue
      Color(0xFF00A3E0), // Bright Blue
      Color(0xFF007BFF), // Standard Blue
      Color(0xFF4ECDC4), // Light Blue
      Color(0xFFF9ED69), // Pale Yellow
      Color(0xFFF5D547), // Yellow
      Color(0xFFFBAA32), // Light Orange (to represent stars)
    ],
  };

  // Set initial color to the first color in the current palette
  Color selectedColor = initialColor ?? colorPalettes[ColorPaletteState.selectedPalette]![0];

  // Use the current selected palette
  String selectedPalette = ColorPaletteState.selectedPalette;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          List<Color> currentPalette = colorPalettes[selectedPalette]!;

          // Reset selectedColor if it's not in the currentPalette
          if (!currentPalette.contains(selectedColor)) {
            selectedColor = currentPalette[0]; // Reset to first color of the new palette
          }

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
                DropdownButton<String>(
                  value: selectedPalette,
                  items: colorPalettes.keys.map((String paletteName) {
                    return DropdownMenuItem<String>(
                      value: paletteName,
                      child: Text(paletteName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPalette = value!;
                      ColorPaletteState.selectedPalette = selectedPalette; // Update the global state
                      // Reset selected color to the first color of the new palette
                      selectedColor = colorPalettes[selectedPalette]![0];
                    });
                  },
                ),
                SizedBox(height: 10),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: currentPalette.map((color) {
                    return DropdownMenuItem<Color>(
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




