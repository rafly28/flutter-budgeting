import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 9)
class Debt extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String type; // 'hutang' (kita meminjam uang) atau 'piutang' (kita meminjamkan uang)

  @HiveField(2)
  String personName;

  @HiveField(3)
  double amount;

  @HiveField(4)
  double paidAmount;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? dueDate;

  @HiveField(7)
  bool isSettled;

  Debt({
    String? id,
    required this.type,
    required this.personName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.createdAt,
    this.dueDate,
    this.isSettled = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
