class Expense {
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String type; // "income" atau "expense"

  Expense({
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.type,
  });
}
