import 'package:hive/hive.dart';

part 'plan_item.g.dart';

@HiveType(typeId: 8) // Menggunakan ID 8
class PlanItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  bool isPaid;

  @HiveField(4)
  String category;

  @HiveField(5)
  String monthKey; // e.g. "2026-07" (Tahun-Bulan) atau string penanda siklus

  @HiveField(6, defaultValue: 'expense')
  String planType;

  PlanItem({
    required this.id,
    required this.title,
    required this.amount,
    this.isPaid = false,
    required this.category,
    required this.monthKey,
    this.planType = 'expense',
  });
}
