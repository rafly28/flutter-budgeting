import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_input_formatter.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedCycle = 1;
  String _selectedCategory = 'Semua'; // 👈 State untuk filter kategori

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final userController = context.watch<UserController>();
    final categoryController = context.watch<CategoryController>();
    final budgetController = context.watch<BudgetController>();

    final int payday = userController.payday;
    final now = DateTime.now();

    // Logika Tanggal Siklus
    DateTime currentCycleEnd = (now.day >= payday)
        ? DateTime(now.year, now.month + 1, payday - 1)
        : DateTime(now.year, now.month, payday - 1);

    DateTime currentCycleStart = (now.day >= payday)
        ? DateTime(now.year, now.month, payday)
        : DateTime(now.year, now.month - 1, payday);

    DateTime targetStartDate = DateTime(
      currentCycleStart.year,
      currentCycleStart.month - (_selectedCycle - 1),
      currentCycleStart.day,
    );

    // Dapatkan list semua kategori untuk Dropdown
    final allCategoryNames = [
      ...categoryController.incomeCategories.map((e) => e.name),
      ...categoryController.expenseCategories.map((e) => e.name),
    ];

    // Jika kategori yang dipilih dihapus, kembalikan ke 'Semua'
    if (_selectedCategory != 'Semua' &&
        !allCategoryNames.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }

    // 🎯 FILTER DATA BERDASARKAN RENTANG WAKTU & KATEGORI
    final timeFilteredExpenses = expenseController.getExpensesByDateRange(
      targetStartDate,
      currentCycleEnd,
    );
    final filteredExpenses = timeFilteredExpenses.where((e) {
      if (_selectedCategory == 'Semua') return true;
      return e.category == _selectedCategory;
    }).toList();

    // Hitung Pemasukan & Pengeluaran
    final double income = filteredExpenses
        .where((e) => e.type == "income")
        .fold(0.0, (s, e) => s + e.amount);
    final double expense = filteredExpenses
        .where((e) => e.type == "expense")
        .fold(0.0, (s, e) => s + e.amount);
    final double balance = income - expense;

    // Cek status budget jika user memilih kategori pengeluaran spesifik
    final double currentBudgetLimit = budgetController.getBudgetLimit(
      _selectedCategory,
    );
    final bool isExpenseCategory = categoryController.expenseCategories.any(
      (c) => c.name == _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Statistik & Budget")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Baris Filter (Siklus & Kategori)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDropdown(
                    value: _selectedCycle,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text("1 Bulan Terakhir"),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text("2 Bulan Terakhir"),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text("3 Bulan Terakhir"),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedCycle = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildDropdown(
                    value: _selectedCategory,
                    items: [
                      const DropdownMenuItem(
                        value: 'Semua',
                        child: Text("Semua Kategori"),
                      ),
                      ...allCategoryNames.map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val as String),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              "Rentang: ${DateFormat('d MMM y', 'id_ID').format(targetStartDate)} - ${DateFormat('d MMM y', 'id_ID').format(currentCycleEnd)}",
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // 🔹 KARTU RINGKASAN ATAU PROGRESS BUDGET
            if (_selectedCategory != 'Semua' && isExpenseCategory)
              _buildBudgetProgressCard(
                context,
                _selectedCategory,
                expense,
                currentBudgetLimit,
                budgetController,
              )
            else
              _buildGeneralSummaryCard(balance, income, expense),

            const SizedBox(height: 20),
            const Text(
              "Rincian Transaksi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: filteredExpenses.isEmpty
                  ? const Center(child: Text("Tidak ada transaksi"))
                  : ListView.builder(
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final exp = filteredExpenses.reversed.toList()[index];
                        return ListTile(
                          leading: Icon(
                            exp.type == "income"
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: exp.type == "income"
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text(exp.category),
                          subtitle: Text(
                            DateFormat('d MMM y', 'id_ID').format(exp.date),
                          ),
                          trailing: Text(
                            CurrencyInputFormatter.format(exp.amount),
                            style: TextStyle(
                              color: exp.type == "income"
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Dropdown
  Widget _buildDropdown({
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Widget Kartu Ringkasan Umum (Jika "Semua" dipilih)
  Widget _buildGeneralSummaryCard(
    double balance,
    double income,
    double expense,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Sisa Uang (Balance)",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 5),
            Text(
              CurrencyInputFormatter.format(balance),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: balance < 0 ? Colors.red : Colors.black,
              ),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pemasukan",
                      style: TextStyle(color: Colors.green),
                    ),
                    Text(
                      CurrencyInputFormatter.format(income),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Pengeluaran",
                      style: TextStyle(color: Colors.red),
                    ),
                    Text(
                      CurrencyInputFormatter.format(expense),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Kartu Progress Budget (Jika Kategori Pengeluaran dipilih)
  Widget _buildBudgetProgressCard(
    BuildContext context,
    String category,
    double spent,
    double limit,
    BudgetController controller,
  ) {
    double progress = limit > 0 ? (spent / limit) : 0.0;
    if (progress > 1.0) progress = 1.0; // Batasi maksimal 100% untuk UI

    Color progressColor = progress >= 0.9
        ? Colors.red
        : (progress >= 0.7 ? Colors.orange : Colors.green);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Budget: $category",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showSetBudgetDialog(
                    context,
                    category,
                    limit,
                    controller,
                  ),
                  child: const Text("Atur Limit"),
                ),
              ],
            ),
            Text(
              "${CurrencyInputFormatter.format(spent)} / ${limit == 0 ? "Belum diatur" : CurrencyInputFormatter.format(limit)}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (limit > 0) ...[
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: progressColor,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 5),
              Text(
                progress >= 1.0
                    ? "⚠️ Anda telah melebihi batas budget!"
                    : "Tersisa: ${CurrencyInputFormatter.format(limit - spent)}",
                style: TextStyle(
                  color: progress >= 1.0 ? Colors.red : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Dialog untuk mengatur Limit Budget
  void _showSetBudgetDialog(
    BuildContext context,
    String category,
    double currentLimit,
    BudgetController controller,
  ) {
    final TextEditingController amountController = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toInt().toString() : "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Atur Limit $category"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Batas Maksimal (Rp)",
            prefixText: "Rp ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              double newLimit = double.tryParse(amountController.text) ?? 0.0;
              controller.setBudgetLimit(category, newLimit);
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
