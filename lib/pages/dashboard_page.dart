import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../controllers/user_controller.dart';
import '../models/expense.dart';
import '../widgets/finance_summary_card.dart'; // Jika masih dipakai, biarkan
import '../utils/currency_input_formatter.dart';
import 'history_page.dart';
import 'add_expense_page.dart';
import 'settings_page.dart';
import 'saving_page.dart';
import 'statistic_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final userController = context.watch<UserController>();

    final user = userController.user;
    final int payday = userController.payday;
    final now = DateTime.now();

    // 🎯 LOGIKA SALDO BERDASARKAN SIKLUS GAJIAN (Bukan 1 Bulan Kalender)
    DateTime currentCycleStart = (now.day >= payday)
        ? DateTime(now.year, now.month, payday)
        : DateTime(now.year, now.month - 1, payday);

    DateTime currentCycleEnd = (now.day >= payday)
        ? DateTime(now.year, now.month + 1, payday - 1)
        : DateTime(now.year, now.month, payday - 1);

    // Ambil data dalam siklus saat ini
    final cycleExpenses = expenseController.getExpensesByDateRange(
      currentCycleStart,
      currentCycleEnd,
    );

    final totalIncome = cycleExpenses
        .where((e) => e.type == "income")
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalExpense = cycleExpenses
        .where((e) => e.type == "expense")
        .fold(0.0, (sum, e) => sum + e.amount);
    final balance = totalIncome - totalExpense;

    // 🎯 TRANSAKSI KHUSUS HARI INI
    final todayExpenses = expenseController.expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .toList();

    final todayTotalExpense = todayExpenses
        .where((e) => e.type == "expense")
        .fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Halo, ${user?.name ?? "User"}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM y', 'id_ID').format(now),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 BAGIAN 1: KARTU SALDO UTAMA MELAYANG (OVERLAPPING)
          Stack(
            children: [
              // Latar belakang biru melengkung yang menyambung dari AppBar
              Container(
                height: 100, // Memberikan efek biru di belakang kartu
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
              ),

              // Kartu Saldo (Tanpa Positioned, pakai Padding agar aman)
              Padding(
                padding: const EdgeInsets.only(
                  top: 15,
                  left: 16,
                  right: 16,
                ), // 👈 Turun 15px dari AppBar agar TIDAK terpotong
                child: FinanceSummaryCard(
                  balance: balance,
                  income: totalIncome,
                  expense: totalExpense,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          // 🔹 BAGIAN 2: MENU CEPAT (GRID)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickMenu(
                  context,
                  "History",
                  Icons.history,
                  Colors.orange,
                  const HistoryPage(),
                ),
                _buildQuickMenu(
                  context,
                  "Statistik",
                  Icons.bar_chart,
                  Colors.purple,
                  const StatisticPage(),
                ),
                _buildQuickMenu(
                  context,
                  "Tabungan",
                  Icons.account_balance_wallet,
                  Colors.teal,
                  const SavingsPage(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 🔹 BAGIAN 3: DAFTAR TRANSAKSI HARI INI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transaksi Hari Ini",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Keluar: ${CurrencyInputFormatter.format(todayTotalExpense)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: todayExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Belum ada transaksi hari ini",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todayExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = todayExpenses.reversed
                          .toList()[index]; // Balik agar yang terbaru di atas

                      return Dismissible(
                        key: ValueKey(exp.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) {
                          expenseController.removeExpense(
                            expenseController.expenses.indexOf(exp),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("🗑️ Transaksi dihapus"),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: exp.type == "transfer"
                                  ? Colors.blue.shade50
                                  : (exp.type == "income"
                                        ? Colors.green.shade50
                                        : Colors.red.shade50),
                              child: Icon(
                                exp.type == "transfer"
                                    ? Icons.sync_alt
                                    : (exp.type == "income"
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward),
                                color: exp.type == "transfer"
                                    ? Colors.blue
                                    : (exp.type == "income"
                                          ? Colors.green
                                          : Colors.red),
                              ),
                            ),
                            title: Text(
                              exp.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              exp.note?.isNotEmpty == true
                                  ? exp.note!
                                  : exp.source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              CurrencyInputFormatter.format(exp.amount),
                              style: TextStyle(
                                color: exp.type == "transfer"
                                    ? Colors.blue
                                    : (exp.type == "income"
                                          ? Colors.green
                                          : Colors.red),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpensePage(expenseToEdit: exp),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 TOMBOL TAMBAH TRANSAKSI
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Catat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // WIDGET HELPER: Menu Cepat
  Widget _buildQuickMenu(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
