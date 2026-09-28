import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:toastification/toastification.dart';

import '../controllers/expense_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/plan_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/debt_controller.dart';
import '../models/expense.dart';
import '../widgets/finance_summary_card.dart'; // Jika masih dipakai, biarkan
import '../utils/currency_input_formatter.dart';
import 'history_page.dart';
import 'add_expense_page.dart';
import 'settings_page.dart';
import 'saving_page.dart';
import 'statistic_page.dart';
import 'planning_page.dart';
import 'debt_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final userController = context.watch<UserController>();
    final categoryController = context.watch<CategoryController>();

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

    double transferOut = cycleExpenses
        .where((e) => e.type == 'transfer' && e.source == 'Budget Utama')
        .fold(0.0, (s, e) => s + e.amount);
    double transferIn = cycleExpenses
        .where((e) => e.type == 'transfer' && e.note != null && e.note!.contains("ke Budget Utama"))
        .fold(0.0, (s, e) => s + e.amount);

    final totalIncome = cycleExpenses
        .where((e) => e.type == "income" && e.source == 'Budget Utama')
        .fold(0.0, (sum, e) => sum + e.amount) + transferIn;
        
    final totalExpense = cycleExpenses
        .where((e) => e.type == "expense" && e.source == 'Budget Utama')
        .fold(0.0, (sum, e) => sum + e.amount) + transferOut;
        
    final balance = userController.resetBalanceOnPayday
        ? totalIncome - totalExpense
        : expenseController.balance;

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
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
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.settings_24_regular, color: Colors.white),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ).animate().fadeIn(delay: 200.ms),
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
                  color: Theme.of(context).colorScheme.primary,
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
                  isHidden: userController.isBalanceHidden,
                  onToggleVisibility: () => userController.toggleBalanceVisibility(),
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
              ),
            ],
          ),

          // 🔹 50-30-20 INDICATOR (tampil jika mode pocket_50_30_20)
          if (userController.budgetingMode == 'pocket_50_30_20') ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              double realNeeds = 0;
              double realWants = 0;
              double realSavings = 0;
              for (final e in cycleExpenses.where((e) => e.type == 'expense')) {
                final catList = categoryController.expenseCategories;
                final cat = catList.where((c) => c.name == e.category).firstOrNull;
                final group = cat?.budgetGroup ?? 'needs';
                if (group == 'wants') realWants += e.amount;
                else if (group == 'savings') realSavings += e.amount;
                else realNeeds += e.amount;
              }
              final targetNeeds = totalIncome * 0.50;
              final targetWants = totalIncome * 0.30;
              final targetSavings = totalIncome * 0.20;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anggaran 50-30-20',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        _build5030Row('Kebutuhan 50%', realNeeds, targetNeeds, Colors.blue.shade600),
                        const SizedBox(height: 10),
                        _build5030Row('Keinginan 30%', realWants, targetWants, Colors.orange.shade600),
                        const SizedBox(height: 10),
                        _build5030Row('Tabungan  20%', realSavings, targetSavings, Colors.green.shade700),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 15),
          // 🔹 BAGIAN 2: MENU CEPAT (GRID)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickMenu(
                    context,
                    "History",
                    FluentIcons.history_24_regular,
                    Colors.orange.shade600,
                    const HistoryPage(),
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
                  _buildQuickMenu(
                    context,
                    "Statistik",
                    FluentIcons.data_bar_vertical_24_regular,
                    Colors.purple.shade600,
                    const StatisticPage(),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                  _buildQuickMenu(
                    context,
                    "Tabungan",
                    FluentIcons.wallet_24_regular,
                    Colors.teal.shade600,
                    const SavingsPage(),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),
                  _buildQuickMenu(
                    context,
                    "Planning",
                    FluentIcons.clipboard_task_24_regular,
                    Colors.blue.shade600,
                    const PlanningPage(),
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2),
                  _buildQuickMenu(
                    context,
                    "Hutang",
                    FluentIcons.handshake_24_regular,
                    Colors.indigo.shade600,
                    const DebtPage(),
                    hasBadge: context.watch<DebtController>().activeHutang.isNotEmpty,
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.2),
                ],
              ),
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
                          FluentIcons.receipt_24_regular,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Belum ada transaksi hari ini",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ).animate().fadeIn(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todayExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = todayExpenses.reversed
                          .toList()[index]; // Balik agar yang terbaru di atas

                      return Dismissible(
                        key: ValueKey(exp.key),
                        direction: exp.debtId == null
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
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
                        confirmDismiss: (_) async {
                          final removed = await expenseController.removeExpense(
                            exp,
                          );
                          if (!context.mounted) return false;
                          if (!removed) {
                            toastification.show(
                              context: context,
                              title: const Text(
                                "Akun transaksi tidak ditemukan. Transaksi belum dihapus.",
                              ),
                              type: ToastificationType.error,
                              style: ToastificationStyle.flat,
                              autoCloseDuration: const Duration(seconds: 3),
                            );
                            return false;
                          }
                          if (exp.planId != null) {
                            context
                                .read<PlanController>()
                                .unmarkPaidByPlanId(exp.planId!);
                          }
                          toastification.show(
                            context: context,
                            title: const Text("🗑️ Transaksi dihapus"),
                            type: ToastificationType.success,
                            style: ToastificationStyle.flat,
                            autoCloseDuration: const Duration(seconds: 3),
                          );
                          return true;
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
                              child: Builder(builder: (ctx) {
                                final catList = exp.type == 'income'
                                    ? categoryController.incomeCategories
                                    : categoryController.expenseCategories;
                                final cat = catList.where((c) => c.name == exp.category).firstOrNull;
                                final iconColor = exp.type == "transfer"
                                    ? Colors.blue
                                    : (exp.type == "income" ? Colors.green : Colors.red);
                                if (exp.type != 'transfer' && cat?.iconCodePoint != null) {
                                  return Icon(
                                    IconData(cat!.iconCodePoint!, fontFamily: cat.iconFontFamily),
                                    color: iconColor,
                                  );
                                }
                                return Icon(
                                  exp.type == "transfer"
                                      ? Icons.sync_alt
                                      : (exp.type == "income" ? Icons.arrow_downward : Icons.arrow_upward),
                                  color: iconColor,
                                );
                              }),
                            ),
                            title: Text(
                              exp.note != null && exp.note!.isNotEmpty ? exp.note! : exp.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: exp.type == 'transfer' ? Colors.blue.shade50 : (exp.type == 'income' ? Colors.green.shade50 : Colors.orange.shade50),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      exp.category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: exp.type == 'transfer' ? Colors.blue.shade700 : (exp.type == 'income' ? Colors.green.shade700 : Colors.orange.shade700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (exp.note != null && exp.note!.isNotEmpty) ? exp.note! : exp.source,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
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
                              if (exp.debtId != null) {
                                toastification.show(
                                  context: context,
                                  title: const Text(
                                    "Kelola transaksi ini dari menu Hutang & Piutang.",
                                  ),
                                  type: ToastificationType.info,
                                  style: ToastificationStyle.flat,
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpensePage(expenseToEdit: exp),
                                ),
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: (100 * (index < 5 ? index : 5)).ms).slideX(begin: 0.1),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 TOMBOL TAMBAH TRANSAKSI
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(FluentIcons.add_24_regular, color: Colors.white),
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
    Widget page, {
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Badge(
              isLabelVisible: hasBadge,
              backgroundColor: Colors.redAccent,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  Widget _build5030Row(String label, double real, double target, Color labelColor) {
    final double pct = target > 0 ? (real / target).clamp(0.0, 1.0) : 0.0;
    final Color barColor = pct >= 1.0 ? Colors.red : (pct >= 0.8 ? Colors.orange : labelColor);
    final int maxPct = label.contains('50') ? 50 : label.contains('30') ? 30 : 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor)),
            Text(
              '${(pct * maxPct).toStringAsFixed(0)}% / $maxPct%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: barColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${CurrencyInputFormatter.formatCompact(real)} / ${CurrencyInputFormatter.formatCompact(target)}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

}
