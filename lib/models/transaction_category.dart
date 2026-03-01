import 'package:hive/hive.dart';

part 'transaction_category.g.dart';

@HiveType(typeId: 5) // Menggunakan ID 5
class TransactionCategory extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String type; // "income" atau "expense"

  TransactionCategory({required this.name, required this.type});
}
