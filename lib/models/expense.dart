import 'package:hive/hive.dart';

part 'expense.g.dart'; // 👈 ini file adapter auto-generated

@HiveType(typeId: 0) // setiap model butuh ID unik
class Expense extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String category;

  @HiveField(2)
  String? note;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String type; // "income" atau "expense"

  @HiveField(5, defaultValue: 'Budget Utama')
  String source;

  Expense({
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.type,
    this.source = 'Budget Utama',
  });
}
