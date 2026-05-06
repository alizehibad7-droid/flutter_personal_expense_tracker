import 'package:flutter/material.dart';

class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense; // true = expense category, false = income category

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });
}

// ─── EXPENSE CATEGORIES ───────────────────────────────────────────────────────
const List<CategoryModel> expenseCategories = [
  CategoryModel(name: 'Food', icon: Icons.restaurant, color: Color(0xFFFF6B6B), isExpense: true),
  CategoryModel(name: 'Travel', icon: Icons.directions_car, color: Color(0xFF4ECDC4), isExpense: true),
  CategoryModel(name: 'Bills', icon: Icons.receipt_long, color: Color(0xFFFFBE0B), isExpense: true),
  CategoryModel(name: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFF845EC2), isExpense: true),
  CategoryModel(name: 'Health', icon: Icons.local_hospital, color: Color(0xFFFF9671), isExpense: true),
  CategoryModel(name: 'Education', icon: Icons.school, color: Color(0xFF00C9A7), isExpense: true),
  CategoryModel(name: 'Entertainment', icon: Icons.movie, color: Color(0xFFF9C74F), isExpense: true),
  CategoryModel(name: 'Rent', icon: Icons.home, color: Color(0xFF4D96FF), isExpense: true),
  CategoryModel(name: 'Other', icon: Icons.category, color: Color(0xFF9B9B9B), isExpense: true),
];

// ─── INCOME CATEGORIES ────────────────────────────────────────────────────────
const List<CategoryModel> incomeCategories = [
  CategoryModel(name: 'Salary', icon: Icons.work, color: Color(0xFF06D6A0), isExpense: false),
  CategoryModel(name: 'Freelance', icon: Icons.computer, color: Color(0xFF118AB2), isExpense: false),
  CategoryModel(name: 'Business', icon: Icons.store, color: Color(0xFF073B4C), isExpense: false),
  CategoryModel(name: 'Gift', icon: Icons.card_giftcard, color: Color(0xFFEF476F), isExpense: false),
  CategoryModel(name: 'Investment', icon: Icons.trending_up, color: Color(0xFF26A65B), isExpense: false),
  CategoryModel(name: 'Rental', icon: Icons.apartment, color: Color(0xFF3D5A80), isExpense: false),
  CategoryModel(name: 'Other', icon: Icons.category, color: Color(0xFF9B9B9B), isExpense: false),
];

// ─── HELPER: get categories by type ──────────────────────────────────────────
List<CategoryModel> getCategoriesForType(bool isExpense) {
  return isExpense ? expenseCategories : incomeCategories;
}

// ─── HELPER: get a single category by name ───────────────────────────────────
CategoryModel getCategoryByName(String name, bool isExpense) {
  final list = getCategoriesForType(isExpense);
  return list.firstWhere(
        (c) => c.name == name,
    orElse: () => isExpense ? expenseCategories.last : incomeCategories.last,
  );
}

// ─── ALL categories combined (for charts) ────────────────────────────────────
List<CategoryModel> get allCategories => [...expenseCategories, ...incomeCategories];