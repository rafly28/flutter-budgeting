import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';
import 'add_expense_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseController>();
    final expenses = controller.expenses;

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Budgeting App"),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Halo user & tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Hello User",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tanggal: ${DateFormat('d MMM y', 'id_ID').format(DateTime.now())}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card keuangan
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Keuangan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyInputFormatter.format(controller.balance),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("Pemasukan"),
                            Text(CurrencyInputFormatter.format(controller.totalIncome)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Pengeluaran"),
                            Text(CurrencyInputFormatter.format(controller.totalExpense)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transaksi hari ini
            Text(
              "Transaksi Hari ini: ${CurrencyInputFormatter.format(
                expenses
                    .where((e) =>
                        e.date.year == DateTime.now().year &&
                        e.date.month == DateTime.now().month &&
                        e.date.day == DateTime.now().day)
                    .fold(0.0, (sum, e) => sum + e.amount),
              )}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text("Belum ada transaksi"))
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final Expense exp = expenses[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                exp.type == "income"
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: exp.type == "income" ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              exp.note == null || exp.note!.isEmpty
                                  ? exp.category
                                  : exp.note!,
                            ),
                            subtitle: Text(
                              DateFormat('d MMM y', 'id_ID').format(exp.date),
                            ),
                            trailing: Text(
                              CurrencyInputFormatter.format(exp.amount),
                              style: TextStyle(
                                color: exp.type == "income" ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Floating button → tambah transaksi
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
