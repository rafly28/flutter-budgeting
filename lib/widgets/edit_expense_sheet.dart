import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';

class EditExpenseSheet extends StatelessWidget {
  final Expense exp;
  final int index;

  const EditExpenseSheet({super.key, required this.exp, required this.index});

  @override
  Widget build(BuildContext context) {
    final noteController = TextEditingController(text: exp.note ?? "");
    final amountController = TextEditingController(text: exp.amount.toString());
    String selectedCategory = exp.category;
    String selectedType = exp.type;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Transaksi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Jumlah"),
          ),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(labelText: "Catatan"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final updated = Expense(
                amount: double.tryParse(amountController.text) ?? exp.amount,
                category: selectedCategory,
                type: selectedType,
                date: exp.date,
                note: noteController.text,
              );
              context.read<ExpenseController>().updateExpense(index, updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✏️ Transaksi berhasil diperbarui")),
              );
            },
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }
}
