import 'package:hive/hive.dart';

part 'category_budget.g.dart';

@HiveType(typeId: 6) // Gunakan ID 6 agar tidak bentrok
class CategoryBudget extends HiveObject {
  @HiveField(0)
  String categoryName;

  @HiveField(1)
  double limitAmount;

  CategoryBudget({required this.categoryName, required this.limitAmount});
}
