import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/helpers.dart';
import 'edit_expense_sheet.dart';

class TodayTransactionList extends StatelessWidget {
  final List<Expense> expenses;

  const TodayTransactionList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text("Belum ada transaksi hari ini"));
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final isToday = DateHelper.isToday(exp.date);

        return Dismissible(
          key: ValueKey(exp.key),
          direction: isToday ? DismissDirection.endToStart : DismissDirection.none,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            if (!isToday) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaksi sudah tutup buku tidak bisa dihapus")),
              );
              return false;
            }
            return true;
          },
          onDismissed: (_) {
            context.read<ExpenseController>().removeExpense(index);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Transaksi dihapus")),
            );
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  exp.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                  color: exp.type == "income" ? Colors.green : Colors.red,
                ),
              ),
              title: Text(exp.note == null || exp.note!.isEmpty ? exp.category : exp.note!),
              subtitle: Text(DateFormat('d MMM y', 'id_ID').format(exp.date)),
              trailing: Text(
                CurrencyInputFormatter.format(exp.amount),
                style: TextStyle(
                  color: exp.type == "income" ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                if (!isToday) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Transaksi sudah tutup buku tidak bisa diedit")),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => EditExpenseSheet(exp: exp, index: index),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
