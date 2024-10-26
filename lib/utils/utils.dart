import 'dart:convert';

import 'package:flutter/material.dart';

String encodeColorToJson(dynamic color) {
  if (color is String) {
    return color;
  } else {
    return color.value.toRadixString(16);
  }
}

String encodeColorsToJson(Set<Color> colors) {
  // Convert each Color to an integer (ARGB) and then encode to JSON
  List<String> colorStrings = colors.map((color) => encodeColorToJson(color))
      .toList();
  return jsonEncode(colorStrings);
}

Color decodeColorFromJson(dynamic hexString) {
  if (hexString is String) {
    return Color(int.parse(hexString, radix: 16));
  }
  if (hexString is int) {
    return Color(hexString as int);
  }
  return const Color(0xFFB2EBF2); // Icy Teal
}

