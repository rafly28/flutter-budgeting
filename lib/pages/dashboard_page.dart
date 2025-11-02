import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import '../controllers/user_controller.dart';
import '../models/expense.dart';
import '../widgets/finance_summary_card.dart';
import '../widgets/dashboard_menu.dart';
import '../utils/currency_input_formatter.dart';
import 'history_page.dart';
import 'add_expense_page.dart';
import 'coming_soon.dart';
import 'statistic_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final user = context.watch<UserController>().user;
    final now = DateTime.now();

    // 🔹 Transaksi bulan ini
    final currentMonthExpenses =
        expenseController.getExpensesByMonth(now.year, now.month);

    final totalIncome = currentMonthExpenses
        .where((e) => e.type == "income")
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalExpense = currentMonthExpenses
        .where((e) => e.type == "expense")
        .fold(0.0, (sum, e) => sum + e.amount);

    final balance = totalIncome - totalExpense;

    // 🔹 Transaksi hari ini
    final todayExpenses = currentMonthExpenses.where((e) =>
        e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day).toList();

    final todayTotalExpense =
        todayExpenses.where((e) => e.type == "expense").fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Halo, ${user?.name ?? "User"} 👋\nHari ini: ${DateFormat('d MMMM y', 'id_ID').format(now)}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          FinanceSummaryCard(
            balance: balance,
            income: totalIncome,
            expense: totalExpense,
          ),

          DashboardMenu(
            items: [
              DashboardMenuItem(
                label: "History",
                icon: Icons.history,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                ),
              ),
              DashboardMenuItem(
                label: "Statistic",
                icon: Icons.bar_chart,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StatisticPage()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            "Total Pengeluaran Hari Ini: ${CurrencyInputFormatter.format(todayTotalExpense)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),
          Expanded(
            child: todayExpenses.isEmpty
                ? const Center(child: Text("Belum ada transaksi hari ini"))
                : ListView.builder(
                    itemCount: todayExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = todayExpenses[index];
                      final isToday = exp.date.year == now.year &&
                          exp.date.month == now.month &&
                          exp.date.day == now.day;

                      return Dismissible(
                        key: ValueKey(exp.key),
                        direction: isToday
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Konfirmasi Hapus"),
                                content: Text(
                                  "Apakah Anda yakin ingin menghapus transaksi ${exp.type == 'income' ? 'Pemasukan' : 'Pengeluaran'} senilai ${CurrencyInputFormatter.format(exp.amount)}?",
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    // Jika menekan BATAL, pop(false) -> item kembali ke posisi semula
                                    onPressed: () => Navigator.of(context).pop(false), 
                                    child: const Text("BATAL"),
                                  ),
                                  TextButton(
                                    // Jika menekan HAPUS, pop(true) -> onDismissed akan dieksekusi
                                    onPressed: () => Navigator.of(context).pop(true), 
                                    child: const Text("HAPUS", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (_) {
                          expenseController.removeExpense(
                            expenseController.expenses.indexOf(exp),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("🗑️ Transaksi dihapus")),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                exp.type == "income"
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: exp.type == "income"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(
                              exp.note?.isNotEmpty == true ? exp.note! : exp.category,
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 FAB utama: tambah transaksi
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          );
        },
      ),
    );
  }
}
