// lib/models/category_model.dart

import 'package:flutter/material.dart';

// A simple plain Dart class (PODO - Plain Old Dart Object)
// No Hive annotations needed since categories are mostly predefined
// We store custom categories as a List<String> in a separate Hive box
class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Static list of predefined categories
// 'static' means it belongs to the CLASS, not to any instance
// 'const' means compile-time constant - never changes at runtime
class AppCategories {
  static const List<CategoryModel> predefined = [
    CategoryModel(
      name: 'Food',
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
    ),
    CategoryModel(
      name: 'Travel',
      icon: Icons.flight,
      color: Color(0xFF4ECDC4),
    ),
    CategoryModel(
      name: 'Bills',
      icon: Icons.receipt_long,
      color: Color(0xFFFFE66D),
    ),
    CategoryModel(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFF95E1D3),
    ),
    CategoryModel(
      name: 'Health',
      icon: Icons.local_hospital,
      color: Color(0xFFF38181),
    ),
    CategoryModel(
      name: 'Entertainment',
      icon: Icons.movie,
      color: Color(0xFFA8E6CF),
    ),
    CategoryModel(
      name: 'Education',
      icon: Icons.school,
      color: Color(0xFFDDA0DD),
    ),
    CategoryModel(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFFB0BEC5),
    ),
  ];

  // Helper method to find a category by name
  static CategoryModel getByName(String name) {
    return predefined.firstWhere(
          (cat) => cat.name == name,
      orElse: () => const CategoryModel(
        name: 'Other',
        icon: Icons.more_horiz,
        color: Color(0xFFB0BEC5),
      ),
    );
  }

  // Get icon for a category name (used in UI)
  static IconData getIcon(String name) => getByName(name).icon;

  // Get color for a category name
  static Color getColor(String name) => getByName(name).color;
}