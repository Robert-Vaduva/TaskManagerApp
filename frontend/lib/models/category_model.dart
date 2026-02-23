import 'package:flutter/material.dart';


class Category {
  final int id;
  final String name;
  final String colorHex;

  Category({required this.id, required this.name, required this.colorHex});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      colorHex: json['color'] ?? "#4F46E5",
    );
  }

  Color get color {
    final hexCode = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}