import 'package:hive/hive.dart';

part 'custom_category_model.g.dart';

@HiveType(typeId: 1)
class CustomCategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isExpense;

  @HiveField(3)
  int colorValue; // store Color as int

  @HiveField(4)
  int iconCodePoint; // store IconData as int

  CustomCategoryModel({
    required this.id,
    required this.name,
    required this.isExpense,
    required this.colorValue,
    required this.iconCodePoint,
  });
}