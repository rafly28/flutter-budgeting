import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

import '../controllers/expense_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_input_formatter.dart';
import '../models/expense.dart';
import '../services/pdf_service.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int _selectedCycle = 1;
  String _selectedCategory = 'Semua';

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

    final allCategoryNames = [
      ...categoryController.incomeCategories.map((e) => e.name),
      ...categoryController.expenseCategories.map((e) => e.name),
    ];

    if (_selectedCategory != 'Semua' &&
        !allCategoryNames.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }

    final timeFilteredExpenses = expenseController.getExpensesByDateRange(
      targetStartDate,
      currentCycleEnd,
    );
    final filteredExpenses = timeFilteredExpenses.where((e) {
      if (_selectedCategory == 'Semua') return true;
      return e.category == _selectedCategory;
    }).toList();

    final double income = filteredExpenses
        .where((e) => e.type == "income")
        .fold(0.0, (s, e) => s + e.amount);
    final double expense = filteredExpenses
        .where((e) => e.type == "expense")
        .fold(0.0, (s, e) => s + e.amount);
    final double balance = income - expense;

    final DateTime prevCycleEnd = targetStartDate.subtract(const Duration(days: 1));
    final DateTime prevCycleStart = DateTime(
      prevCycleEnd.year,
      prevCycleEnd.month - (_selectedCycle - 1),
      payday,
    );
    final prevTimeFilteredExpenses = expenseController.getExpensesByDateRange(
      prevCycleStart,
      prevCycleEnd,
    );
    final prevFilteredExpenses = prevTimeFilteredExpenses.where((e) {
      if (_selectedCategory == 'Semua') return true;
      return e.category == _selectedCategory;
    }).toList();
    final double prevExpense = prevFilteredExpenses
        .where((e) => e.type == "expense")
        .fold(0.0, (s, e) => s + e.amount);

    final double currentBudgetLimit = budgetController.getBudgetLimit(
      _selectedCategory,
    );
    final bool isExpenseCategory = categoryController.expenseCategories.any(
      (c) => c.name == _selectedCategory,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Tema Dashboard
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Statistik & Budget",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Ekspor ke PDF',
            onPressed: () async {
              toastification.show(
                context: context,
                title: const Text('Menyiapkan dokumen PDF...'),
                type: ToastificationType.info,
                style: ToastificationStyle.flat,
                autoCloseDuration: const Duration(seconds: 3),
              );
              await PdfService.exportAndShareMonthlyReport(
                month: currentCycleStart.month,
                year: currentCycleStart.year,
                totalIncome: income,
                totalExpense: expense,
                finalBalance: balance,
                expenses: timeFilteredExpenses, // We pass all expenses for this time period
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            //  Latar Belakang Biru Melengkung
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),

            //  Konten Utama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  //  CARD FILTER
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  onChanged: (val) =>
                                      setState(() => _selectedCycle = val!),
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
                                      (name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) => setState(
                                    () => _selectedCategory = val as String,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "${DateFormat('d MMM y', 'id_ID').format(targetStartDate)} - ${DateFormat('d MMM y', 'id_ID').format(currentCycleEnd)}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  //  KARTU EVALUASI (Jika Semua Kategori) ATAU KARTU PROGRESS
                  if (_selectedCategory == 'Semua')
                    _buildBudgetSummaryStatus(
                      timeFilteredExpenses,
                      categoryController,
                      budgetController,
                      prevExpense,
                    ),

                  if (_selectedCategory != 'Semua' && isExpenseCategory)
                    _buildBudgetProgressCard(
                      context,
                      _selectedCategory,
                      expense,
                      currentBudgetLimit,
                      budgetController,
                      prevExpense,
                    )
                  else if (_selectedCategory != 'Semua')
                    _buildGeneralSummaryCard(balance, income, expense, prevExpense),

                  const SizedBox(height: 15),

                  // TOP KATEGORI PENGELUARAN
                  if (_selectedCategory == 'Semua') ...[
                    Builder(builder: (context) {
                      final onlyExpenses = timeFilteredExpenses.where((e) => e.type == 'expense').toList();
                      if (onlyExpenses.isEmpty) return const SizedBox.shrink();
                      // Kelompokkan per kategori
                      final Map<String, double> catTotals = {};
                      for (final e in onlyExpenses) {
                        catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
                      }
                      final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                      final top = sorted.take(5).toList();
                      final double maxVal = top.isNotEmpty ? top.first.value : 1;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Top Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 12),
                              ...top.map((entry) {
                                final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
                                final cat = categoryController.expenseCategories.where((c) => c.name == entry.key).firstOrNull;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (cat?.iconCodePoint != null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: Icon(IconData(cat!.iconCodePoint!, fontFamily: cat.iconFontFamily), size: 14, color: Colors.red.shade600),
                                            ),
                                          Expanded(
                                            child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                          ),
                                          Text(
                                            CurrencyInputFormatter.formatCompact(entry.value),
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 7,
                                          backgroundColor: Colors.grey.shade200,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // KOMPARASI 50-30-20 MAKRO
                  if (_selectedCategory == 'Semua' && userController.budgetingMode == 'pocket_50_30_20') ...[
                    Builder(builder: (context) {
                      final incomeAmt = timeFilteredExpenses.where((e) => e.type == 'income').fold(0.0, (s, e) => s + e.amount);
                      if (incomeAmt <= 0) return const SizedBox.shrink();
                      double realNeeds = 0, realWants = 0, realSavings = 0;
                      for (final e in timeFilteredExpenses.where((e) => e.type == 'expense')) {
                        final cat = categoryController.expenseCategories.where((c) => c.name == e.category).firstOrNull;
                        final group = cat?.budgetGroup ?? 'needs';
                        if (group == 'wants') realWants += e.amount;
                        else if (group == 'savings') realSavings += e.amount;
                        else realNeeds += e.amount;
                      }
                      int pNeeds = ((realNeeds / incomeAmt) * 100).round();
                      int pWants = ((realWants / incomeAmt) * 100).round();
                      int pSavings = ((realSavings / incomeAmt) * 100).round();
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Komparasi 50-30-20', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              const Text('Rasio ideal vs realisasi bulan ini', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 12),
                              _buildMacroRow('Kebutuhan', 50, pNeeds, Colors.blue.shade600),
                              const SizedBox(height: 8),
                              _buildMacroRow('Keinginan', 30, pWants, Colors.orange.shade600),
                              const SizedBox(height: 8),
                              _buildMacroRow('Tabungan', 20, pSavings, Colors.green.shade700),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 25),
                  const Text(
                    "Rincian Transaksi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  //  DAFTAR TRANSAKSI
                  if (filteredExpenses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Tidak ada transaksi",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final exp = filteredExpenses.reversed.toList()[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: exp.type == "income"
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              child: Builder(
                                builder: (context) {
                                  final catCtrl = context.read<CategoryController>();
                                  final catList = exp.type == 'income' ? catCtrl.incomeCategories : catCtrl.expenseCategories;
                                  final category = catList.where((c) => c.name == exp.category).firstOrNull;
                                  
                                  if (category?.iconCodePoint != null) {
                                    return Icon(
                                      IconData(category!.iconCodePoint!, fontFamily: category.iconFontFamily),
                                      color: exp.type == "income"
                                          ? Colors.green
                                          : Colors.red,
                                    );
                                  }
                                  
                                  return Icon(
                                    exp.type == "income"
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: exp.type == "income"
                                        ? Colors.green
                                        : Colors.red,
                                  );
                                }
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
                              DateFormat('d MMM y', 'id_ID').format(exp.date),
                            ),
                            trailing: Text(
                              CurrencyInputFormatter.format(exp.amount),
                              style: TextStyle(
                                color: exp.type == "income"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET HELPERS
  Widget _buildDropdown({
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more, color: Colors.grey),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryStatus(
    List<Expense> currentCycleExpenses,
    CategoryController categoryController,
    BudgetController budgetController,
    double prevExpense,
  ) {
    int overLimitCount = 0;
    int underLimitCount = 0;
    double totalLimit = 0;

    for (var cat in categoryController.expenseCategories) {
      double limit = budgetController.getBudgetLimit(cat.name);
      if (limit > 0) {
        totalLimit += limit;
        double spent = currentCycleExpenses
            .where((e) => e.category == cat.name && e.type == "expense")
            .fold(0.0, (s, e) => s + e.amount);
        if (spent > limit) {
          overLimitCount++;
        } else {
          underLimitCount++;
        }
      }
    }

    if (totalLimit == 0) return const SizedBox.shrink();

    bool isSafe = overLimitCount == 0;

    return Card(
      elevation: 0,
      color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSafe ? Colors.green.shade300 : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isSafe ? Icons.check_circle : Icons.warning_rounded,
                  color: isSafe ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isSafe ? "Bulan Ini Aman!" : "Ada Budget Yang Jebol!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Builder(builder: (ctx) {
                final double currentSpent = currentCycleExpenses.where((e) => e.type == "expense").fold(0.0, (s, e) => s + e.amount);
                final double diff = currentSpent - prevExpense;
                final bool isMore = diff > 0;
                if (prevExpense == 0) return const Text("Belum ada data bulan lalu", style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold));
                final pct = (diff.abs() / prevExpense) * 100;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isMore ? Icons.trending_up : Icons.trending_down, size: 16, color: isMore ? Colors.red : Colors.green),
                    const SizedBox(width: 5),
                    Text(
                      "${isMore ? '+' : '-'}${pct.toStringAsFixed(1)}% pengeluaran dibanding lalu",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMore ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryStat(
                  "Aman",
                  underLimitCount.toString(),
                  Colors.green,
                ),
                _buildSummaryStat(
                  "Jebol",
                  overLimitCount.toString(),
                  Colors.red,
                ),
                _buildSummaryStat(
                  "Total Limit",
                  CurrencyInputFormatter.format(totalLimit),
                  Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSummaryCard(
    double balance,
    double income,
    double expense,
    double prevExpense,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Total ${balance >= 0 ? 'Surplus' : 'Defisit'}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              CurrencyInputFormatter.format(balance),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: balance < 0 ? Colors.red : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Builder(builder: (ctx) {
                final double diff = expense - prevExpense;
                final bool isMore = diff > 0;
                if (prevExpense == 0) return const Text("Belum ada data bulan lalu", style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold));
                final pct = (diff.abs() / prevExpense) * 100;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isMore ? Icons.trending_up : Icons.trending_down, size: 16, color: isMore ? Colors.red : Colors.green),
                    const SizedBox(width: 5),
                    Text(
                      "${isMore ? '+' : '-'}${pct.toStringAsFixed(1)}% pengeluaran dibanding lalu",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMore ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                );
              }),
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
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyInputFormatter.format(income),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Pengeluaran",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyInputFormatter.format(expense),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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

  Widget _buildBudgetProgressCard(
    BuildContext context,
    String category,
    double spent,
    double limit,
    BudgetController controller,
    double prevExpense,
  ) {
    double progress = limit > 0 ? (spent / limit) : 0.0;
    if (progress > 1.0) progress = 1.0;
    Color progressColor = progress >= 0.9
        ? Colors.red
        : (progress >= 0.7 ? Colors.orange : Colors.green);

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                if (limit == 0)
                  const Text(
                    "Belum diatur",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${CurrencyInputFormatter.format(spent)} / ${limit == 0 ? "-" : CurrencyInputFormatter.format(limit)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (limit > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  color: progressColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progress >= 1.0
                        ? "Melebihi budget!"
                        : "Tersisa: ${CurrencyInputFormatter.format(limit - spent)}",
                    style: TextStyle(
                      color: progress >= 1.0 ? Colors.red : Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Builder(builder: (ctx) {
                    final double diff = spent - prevExpense;
                    final bool isMore = diff > 0;
                    if (prevExpense == 0) return const SizedBox.shrink();
                    final pct = (diff.abs() / prevExpense) * 100;
                    return Row(
                      children: [
                        Icon(isMore ? Icons.trending_up : Icons.trending_down, size: 14, color: isMore ? Colors.red : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "${isMore ? '+' : '-'}${pct.toStringAsFixed(1)}% vs lalu",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMore ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildMacroRow(String label, int idealPct, int realPct, Color color) {
    final bool overBudget = realPct > idealPct;
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Ideal: $idealPct%', style: TextStyle(fontSize: 10, color: color)),
                  const SizedBox(width: 8),
                  Text('Riil: $realPct%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: overBudget ? Colors.red : Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 3),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (idealPct / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (realPct / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.transparent,
                      color: overBudget ? Colors.red : color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

}
