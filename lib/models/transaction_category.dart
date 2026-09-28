import 'package:hive/hive.dart';

part 'transaction_category.g.dart';

@HiveType(typeId: 5) // Menggunakan ID 5
class TransactionCategory extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String type; // "income" atau "expense"

  @HiveField(2)
  int? iconCodePoint;

  @HiveField(3)
  String? iconFontFamily;

  @HiveField(4, defaultValue: 'needs')
  String budgetGroup; // 'needs', 'wants', 'savings'

  TransactionCategory({
    required this.name,
    required this.type,
    this.iconCodePoint,
    this.iconFontFamily,
    this.budgetGroup = 'needs',
  });
}
