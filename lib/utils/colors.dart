// Define the color palettes as constants
import 'package:flutter/material.dart';

const Map<String, List<Color>> colorPalettes = {
  'Sushi': [
    Color(0xFFFA8072), // Salmon (Salmon Pink)
    Color(0xFFF5CBA7), // Shrimp (Light Pink)
    Color(0xFFFFD700), // Egg (Golden Yellow)
    Color(0xFF8B4513), // Eel (Dark Brown)
    Color(0xFFFF4500), // Tuna (Red)
    Color(0xFF98FB98), // Wasabi (Light Green)
    Color(0xFF2E8B57), // Seaweed (Dark Green)
    Color(0xFFFFF5EE), // Rice (Light Cream)
    Color(0xFFA52A2A), // Tobiko (Orange-Brown)
    Color(0xFFFFA07A), // Roe (Light Salmon)
  ],
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
    Color(0xFFBBDEFA), // Icy Soft Blue
    Color(0xFFE0E0E0), // Icy Grey
    Color(0xFFE1F5FE), // Icy Pale Blue
  ],
  'Au'
      ''
      'tumn': [
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


// Function to find the palette containing the initialColor
String? findPaletteContainingColor(Map<String, List<Color>> colorPalettes, Color initialColor) {
  for (var entry in colorPalettes.entries) {
    if (entry.value.contains(initialColor)) {
      return entry.key; // Return the name of the palette containing the color
    }
  }
  return null; // Return null if the color is not found in any palette
}