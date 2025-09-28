import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseListWidget extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseListWidget({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text("Belum ada pengeluaran"),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.money),
            title: Text("Rp ${exp.amount.toStringAsFixed(0)}"),
            subtitle: Text(
              "${exp.category} - ${exp.date.toLocal().toString().split(' ')[0]}",
            ),
            trailing: exp.note != null && exp.note!.isNotEmpty
                ? Text(exp.note!)
                : null,
          ),
        );
      },
    );
  }
}
