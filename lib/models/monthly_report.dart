import 'package:hive/hive.dart';

part 'monthly_report.g.dart';

@HiveType(typeId: 2) // pakai id unik berbeda dengan Expense
class MonthlyReport extends HiveObject {
  @HiveField(0)
  late String month; // format: yyyy-MM

  @HiveField(1)
  late double totalIncome;

  @HiveField(2)
  late double totalExpense;

  @HiveField(3)
  late double balance;

  MonthlyReport({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });
}
