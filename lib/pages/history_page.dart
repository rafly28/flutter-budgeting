import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseController>().expenses;

    final currencyFormatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );

    // formatter untuk tanggal
    final dateFormatter = DateFormat('d MMM y', 'id_ID');

    if (expenses.isEmpty) {
      return const Center(child: Text("Belum ada pengeluaran"));
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final Expense exp = expenses[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.money),
            title: Text(currencyFormatter.format(exp.amount)),
            subtitle: Text(
              "${exp.note} - ${dateFormatter.format(exp.date)}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<ExpenseController>().removeExpense(index);
              },
            ),
          ),
        );
      },
    );
  }
}
