// lib/models/transaction_model.dart

import 'package:hive/hive.dart';

// This tells Hive to generate the TypeAdapter for this class
// Run: flutter pub run build_runner build
part 'transaction_model.g.dart';

// @HiveType marks this class for Hive serialization
// typeId must be unique across all Hive models in your app
@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  // @HiveField assigns a unique index to each field
  // These indices must NEVER change once data is stored (would corrupt existing data)
  @HiveField(0)
  String id;

  @HiveField(1)
  String title; // Short description / note

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category; // e.g. "Food", "Travel", etc.

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isExpense; // true = expense, false = income

  @HiveField(6)
  String note; // Additional note

  // Constructor - named parameters with required keyword
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
    this.note = '',
  });
}