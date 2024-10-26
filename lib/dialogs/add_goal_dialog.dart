import 'package:flutter/material.dart';

import '../utils/colors.dart';

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

  // Print initial color
  print("My Color: $initialColor");

  // Use the current selected palette
  String selectedPalette = ColorPaletteState.selectedPalette;

  // Set initial color to the first color in the current palette
  Color selectedColor = initialColor ?? colorPalettes[selectedPalette]![0];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {

          List<Color>? currentPalette = colorPalettes[selectedPalette]!;
          // Reset selectedColor if it's not in the currentPalette
          if (!currentPalette.contains(selectedColor)) {
            String? paletteName = findPaletteContainingColor(colorPalettes, selectedColor);
            if(paletteName == null) {
              setState(()  {
                selectedPalette = colorPalettes.entries.first.key;
              });
            } else {
              setState(()  {
                selectedPalette = paletteName;
              });
            }
            print("Palette $paletteName > $currentPalette");
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
                      // Update the global state
                      ColorPaletteState.selectedPalette = selectedPalette;
                      // Reset selected color to the first color of the new palette
                      selectedColor = colorPalettes[selectedPalette]![0];
                    });
                  },
                ),
                SizedBox(height: 10),
                DropdownButton<Color>(
                  value: selectedColor,
                  items: colorPalettes[selectedPalette]!.map((color) {
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




