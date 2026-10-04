import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/plan_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../controllers/saving_controller.dart';
import '../models/plan_item.dart';
import '../utils/currency_input_formatter.dart';
import 'add_expense_page.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String currentMonthKey;
  late String previousMonthKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Setup logic for auto-recurring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userController = context.read<UserController>();
      final planController = context.read<PlanController>();

      final now = DateTime.now();
      final payday = userController.payday;

      // Hitung currentCycle
      DateTime currentCycleStart = (now.day >= payday)
          ? DateTime(now.year, now.month, payday)
          : DateTime(now.year, now.month - 1, payday);

      DateTime previousCycleStart = DateTime(
        currentCycleStart.year,
        currentCycleStart.month - 1,
        currentCycleStart.day,
      );

      currentMonthKey =
          "${currentCycleStart.year}-${currentCycleStart.month.toString().padLeft(2, '0')}-Cycle";
      previousMonthKey =
          "${previousCycleStart.year}-${previousCycleStart.month.toString().padLeft(2, '0')}-Cycle";

      planController.autoCopyFromPreviousMonth(
        currentMonthKey,
        previousMonthKey,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPlanDialog(BuildContext context, {PlanItem? plan}) {
    final titleController = TextEditingController(text: plan?.title);
    final amountController = TextEditingController(
      text: plan != null ? NumberFormat.decimalPattern("id_ID").format(plan.amount.toInt()) : "",
    );
    String selectedPlanType = plan?.planType ?? 'expense';
    String selectedCategory = plan?.category ?? "Semua";

    showDialog(
      context: context,
      builder: (context) {
        final categoryController = context.watch<CategoryController>();
        final savingController = context.watch<SavingController>();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final allExpenseCategories = [
              "Semua",
              ...categoryController.expenseCategories.map((e) => e.name),
            ];
            final allSavingAccounts = savingController.savings.map((e) => e.name).toList();

            List<String> currentDropdownItems = selectedPlanType == 'expense'
                ? allExpenseCategories
                : (allSavingAccounts.isEmpty ? ["Belum Ada Rekening"] : allSavingAccounts);

            if (!currentDropdownItems.contains(selectedCategory)) {
              selectedCategory = currentDropdownItems.first;
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                plan == null ? "Tambah Tagihan/Goal" : "Edit Tagihan/Goal",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nama Tagihan",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Contoh: Listrik",
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Nominal Target",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Jenis Target",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedPlanType = 'expense';
                                selectedCategory = "Semua";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedPlanType == 'expense' ? Theme.of(context).colorScheme.primary : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPlanType == 'expense' ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Pengeluaran",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selectedPlanType == 'expense' ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                selectedPlanType = 'saving';
                                selectedCategory = savingController.savings.isNotEmpty 
                                    ? savingController.savings.first.name 
                                    : "Belum Ada Rekening";
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedPlanType == 'saving' ? Theme.of(context).colorScheme.primary : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPlanType == 'saving' ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Tabungan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selectedPlanType == 'saving' ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      selectedPlanType == 'expense' ? "Kategori Budget" : "Pilih Tabungan Tujuan",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedCategory),
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: currentDropdownItems
                          .map(
                            (c) => DropdownMenuItem(
                              value: c, 
                              child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                          .toList(),
                      onChanged: currentDropdownItems.contains("Belum Ada Rekening") 
                          ? null 
                          : (val) {
                              setStateDialog(() => selectedCategory = val!);
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      return;
                    }

                    final String cleanAmount = amountController.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final double amount = double.tryParse(cleanAmount) ?? 0.0;
                    if (amount <= 0) return;

                    final newPlan = PlanItem(
                      id:
                          plan?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      amount: amount,
                      category: selectedCategory,
                      monthKey: currentMonthKey,
                      isPaid: plan?.isPaid ?? false,
                      planType: selectedPlanType,
                    );

                    if (plan == null) {
                      context.read<PlanController>().addPlan(newPlan);
                    } else {
                      context.read<PlanController>().updatePlanByKey(
                        plan.key,
                        newPlan,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Simpan"
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: const Text(
          "Planning & Goals",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Daftar Tagihan"),
            Tab(text: "Progress Budget"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChecklistTab(), _buildProgressTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlanDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah", ),
      ),
    );
  }

  Widget _buildChecklistTab() {
    final planController = context.watch<PlanController>();

    // Gunakan monthKey yang diset di initState
    // Jika belum inisialisasi, gunakan fallback
    final now = DateTime.now();
    final payday = context.watch<UserController>().payday;
    DateTime currentCycleStart = (now.day >= payday)
        ? DateTime(now.year, now.month, payday)
        : DateTime(now.year, now.month - 1, payday);
    String activeMonthKey =
        "${currentCycleStart.year}-${currentCycleStart.month.toString().padLeft(2, '0')}-Cycle";

    final currentPlans = planController.getPlansByMonth(activeMonthKey);

    if (currentPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            const Text(
              "Belum ada tagihan/plan bulan ini",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    double totalPlanned = currentPlans.fold(0.0, (s, e) => s + e.amount);
    double totalPaid = currentPlans
        .where((e) => e.isPaid)
        .fold(0.0, (s, e) => s + e.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Direncanakan:",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyInputFormatter.format(totalPlanned),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sudah Dibayar:",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyInputFormatter.format(totalPaid),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: totalPlanned > 0 ? totalPaid / totalPlanned : 0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: currentPlans.length,
            itemBuilder: (context, index) {
              final plan = currentPlans[index];
              return Dismissible(
                key: ValueKey(plan.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => planController.removePlan(plan.key),
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Checkbox(
                      value: plan.isPaid,
                      activeColor: Colors.green,
                      onChanged: (val) async {
                        if (val == true) {
                          // Jika akan ditandai sudah dibayar, arahkan ke AddExpensePage
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddExpensePage(planToPay: plan),
                            ),
                          );
                        } else {
                          // Jika di-uncheck, cukup ubah status
                          planController.togglePaidStatus(plan.key);
                        }
                      },
                    ),
                    title: Text(
                      plan.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: plan.isPaid
                            ? TextDecoration.lineThrough
                            : null,
                        color: plan.isPaid ? Colors.grey : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      plan.planType == 'saving' ? "Ke: ${plan.category}" : plan.category,
                      style: TextStyle(fontSize: 12, color: plan.planType == 'saving' ? Theme.of(context).colorScheme.primary : Colors.grey),
                    ),
                    trailing: Text(
                      CurrencyInputFormatter.format(plan.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: plan.isPaid ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: () => _showAddPlanDialog(context, plan: plan),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    final expenseController = context.watch<ExpenseController>();
    final budgetController = context.watch<BudgetController>();
    final categoryController = context.watch<CategoryController>();

    final now = DateTime.now();
    final payday = context.watch<UserController>().payday;
    DateTime currentCycleStart = (now.day >= payday)
        ? DateTime(now.year, now.month, payday)
        : DateTime(now.year, now.month - 1, payday);
    DateTime currentCycleEnd = (now.day >= payday)
        ? DateTime(now.year, now.month + 1, payday - 1)
        : DateTime(now.year, now.month, payday - 1);

    final cycleExpenses = expenseController.getExpensesByDateRange(
      currentCycleStart,
      currentCycleEnd,
    );

    final expenseCategories = categoryController.expenseCategories;
    final savingAccounts = context.watch<SavingController>().savings;
    final currentPlans = context.watch<PlanController>().getPlansByMonth("${currentCycleStart.year}-${currentCycleStart.month.toString().padLeft(2, '0')}-Cycle");

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expenseCategories.isNotEmpty) ...[
          const Text(
            "Progress Pengeluaran",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 10),
          ...expenseCategories.map((cat) {
            final limit = budgetController.getBudgetLimit(cat.name);
            final spent = cycleExpenses
                .where((e) => e.category == cat.name && e.type == "expense")
                .fold(0.0, (s, e) => s + e.amount);

            double progress = limit > 0 ? (spent / limit) : 0.0;
            if (progress > 1.0) progress = 1.0;

            Color progressColor = progress >= 0.9
                ? Colors.red
                : (progress >= 0.7 ? Colors.orange : Colors.green);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(

                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      limit > 0
                          ? "${(progress * 100).toStringAsFixed(1)}%"
                          : "No Limit",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (limit > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Terpakai: ${CurrencyInputFormatter.format(spent)}",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    if (limit > 0)
                      Text(
                        "Limit: ${CurrencyInputFormatter.format(limit)}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
      ],
      if (savingAccounts.isNotEmpty) ...[
        if (expenseCategories.isNotEmpty) const SizedBox(height: 20),
        const Text(
          "Progress Tabungan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 10),
        ...savingAccounts.map((cat) {
          final target = currentPlans
              .where((p) => p.planType == 'saving' && p.category == cat.name)
              .fold(0.0, (s, e) => s + e.amount);
          
          final spent = cycleExpenses
              .where((e) => e.type == "transfer" && e.note != null && e.note!.contains("ke ${cat.name}"))
              .fold(0.0, (s, e) => s + e.amount);

          double progress = target > 0 ? (spent / target) : 0.0;
          if (progress > 1.0) progress = 1.0;

          Color progressColor = progress >= 1.0
              ? Colors.green
              : Theme.of(context).colorScheme.primary;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        target > 0
                            ? "${(progress * 100).toStringAsFixed(1)}%"
                            : "No Target",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (target > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: progressColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Terkumpul: ${CurrencyInputFormatter.format(spent)}",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      if (target > 0)
                        Text(
                          "Target: ${CurrencyInputFormatter.format(target)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ]
    ],
  );
}
}
