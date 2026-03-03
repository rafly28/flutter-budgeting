import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../controllers/saving_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class AddExpensePage extends StatefulWidget {
  final DateTime? fixedDate;
  final Expense? expenseToEdit;

  const AddExpensePage({super.key, this.fixedDate, this.expenseToEdit});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategory;
  String _selectedSource = 'Budget Utama';
  String _selectedDestination = 'Budget Utama';

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    // 🎯 LOGIKA PRE-FILL (Mengisi form jika sedang mode Edit)
    if (widget.expenseToEdit != null) {
      final exp = widget.expenseToEdit!;
      _amountController.text = NumberFormat.decimalPattern(
        "id_ID",
      ).format(exp.amount.toInt());
      _selectedType = exp.type;
      _selectedCategory = exp.category;
      _selectedSource = exp.source;
      _selectedDate = exp.date;

      // Ekstrak tujuan transfer dan catatan asli
      if (exp.type == 'transfer' && exp.note != null) {
        final noteString = exp.note!;
        if (noteString.startsWith("Dari ")) {
          final firstDot = noteString.indexOf(".");
          if (firstDot != -1) {
            final transferInfo = noteString.substring(0, firstDot);
            final parts = transferInfo.split(" ke ");
            if (parts.length > 1) _selectedDestination = parts[1];
            if (noteString.length > firstDot + 2) {
              _noteController.text = noteString.substring(firstDot + 2).trim();
            }
          } else {
            _noteController.text = noteString;
          }
        }
      } else {
        _noteController.text = exp.note ?? '';
      }
    } else {
      _selectedDate = widget.fixedDate ?? DateTime.now();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCategoryList());
  }

  void _updateCategoryList() {
    if (_selectedType == 'transfer') {
      setState(() => _selectedCategory = 'Transfer');
      return;
    }
    final catController = context.read<CategoryController>();
    final categories = _selectedType == 'expense'
        ? catController.expenseCategories
        : catController.incomeCategories;

    if (categories.isNotEmpty) {
      setState(() {
        if (widget.expenseToEdit == null ||
            !categories.any((c) => c.name == _selectedCategory)) {
          _selectedCategory = categories.first.name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catController = context.watch<CategoryController>();
    final savingController = context.watch<SavingController>();

    final categories = _selectedType == 'expense'
        ? catController.expenseCategories
        : catController.incomeCategories;
    final accountOptions = [
      'Budget Utama',
      ...savingController.savings.map((s) => s.name),
    ];

    if (!accountOptions.contains(_selectedDestination))
      _selectedDestination = accountOptions.first;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tanggal Transaksi",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              DateFormat('EEEE, d MMMM y', 'id_ID').format(_selectedDate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ), // 👈 Jarak kartu ke layar dirapatkan
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    18.0,
                  ), // 👈 Jarak dalam kartu dirapatkan (dari 24 ke 18)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 1. PEMILIHAN TIPE TRANSAKSI
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildTypeButton(
                              'Pengeluaran',
                              'expense',
                              Colors.red,
                            ),
                            _buildTypeButton(
                              'Pemasukan',
                              'income',
                              Colors.green,
                            ),
                            _buildTypeButton(
                              'Transfer',
                              'transfer',
                              Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18), // 👈 Dirapatkan
                      // 🔹 2. NOMINAL
                      const Text(
                        "Nominal",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6), // 👈 Dirapatkan
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ), // Sedikit dikecilkan agar proporsional
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ), // 👈 Dirapatkan
                        ),
                      ),
                      const SizedBox(height: 15), // 👈 Dirapatkan
                      // 🔹 3. KATEGORI
                      if (_selectedType != 'transfer') ...[
                        const Text(
                          "Kategori",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            isDense: true, // 👈 Membuat dropdown lebih compact
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val),
                        ),
                        const SizedBox(height: 15), // 👈 Dirapatkan
                      ],

                      // 🔹 4. SUMBER DANA & TUJUAN DANA
                      if (_selectedType == 'transfer') ...[
                        Container(
                          padding: const EdgeInsets.all(12), // 👈 Dirapatkan
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.blue.shade50.withOpacity(0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Dari (Sumber Dana)",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: _selectedSource,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                items: accountOptions
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedSource = val!),
                              ),
                              const Divider(height: 16), // 👈 Dirapatkan
                              const Text(
                                "Ke (Tujuan Dana)",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: _selectedDestination,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                items: accountOptions
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedDestination = val!),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Sumber / Tujuan Dana",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedSource,
                          decoration: InputDecoration(
                            isDense: true, // 👈 Membuat dropdown lebih compact
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: accountOptions
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSource = val!),
                        ),
                      ],

                      const SizedBox(height: 15), // 👈 Dirapatkan
                      // 🔹 5. CATATAN
                      const Text(
                        "Catatan (Opsional)",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Tulis detail transaksi...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 25), // 👈 Dirapatkan
                      // 🔹 6. TOMBOL SIMPAN
                      SizedBox(
                        width: double.infinity,
                        height: 50, // 👈 Sedikit dikecilkan agar senada
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            backgroundColor: _selectedType == 'expense'
                                ? Colors.red.shade600
                                : (_selectedType == 'income'
                                      ? Colors.green.shade600
                                      : Colors.blue.shade600),
                          ),
                          onPressed: _handleSave,
                          child: Text(
                            widget.expenseToEdit != null
                                ? 'Simpan Perubahan'
                                : 'Simpan Transaksi',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, String value, Color activeColor) {
    bool isActive = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = value;
            _updateCategoryList();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;

    final String cleanAmount = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final double amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) return;

    if (_selectedType == 'transfer' &&
        _selectedSource == _selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sumber dan Tujuan tidak boleh sama!')),
      );
      return;
    }

    if (_selectedType == 'expense' && _selectedSource == 'Budget Utama') {
      final budgetController = context.read<BudgetController>();
      final expenseController = context.read<ExpenseController>();
      double limit = budgetController.getBudgetLimit(_selectedCategory!);

      if (limit > 0) {
        final currentMonthExpenses = expenseController.getExpensesByMonth(
          _selectedDate.year,
          _selectedDate.month,
        );
        double alreadySpent = currentMonthExpenses
            .where(
              (e) =>
                  e.category == _selectedCategory &&
                  e.type == 'expense' &&
                  e != widget.expenseToEdit,
            )
            .fold(0.0, (s, e) => s + e.amount);

        if ((alreadySpent + amount) > limit) {
          _showBudgetWarningDialog(amount, limit, alreadySpent);
          return;
        }
      }
    }

    _saveData(amount);
  }

  void _showBudgetWarningDialog(
    double newAmount,
    double limit,
    double alreadySpent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Peringatan Budget!'),
          ],
        ),
        content: Text(
          'Transaksi ini akan melebihi limit budget kategori $_selectedCategory.\n\nSisa Budget: ${CurrencyInputFormatter.format(limit - alreadySpent)}\n\nTetap simpan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _saveData(newAmount);
            },
            child: const Text(
              'Tetap Simpan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveData(double amount) {
    final savingCtrl = context.read<SavingController>();
    final expenseCtrl = context.read<ExpenseController>();

    if (widget.expenseToEdit != null) {
      final oldExp = widget.expenseToEdit!;
      if (oldExp.type == 'transfer') {
        String oldDest = 'Budget Utama';
        if (oldExp.note != null && oldExp.note!.startsWith("Dari ")) {
          final firstDot = oldExp.note!.indexOf(".");
          if (firstDot != -1) {
            final parts = oldExp.note!.substring(0, firstDot).split(" ke ");
            if (parts.length > 1) oldDest = parts[1];
          }
        }
        _updateSavingBalance(
          savingCtrl,
          oldExp.source,
          oldExp.amount,
          'income',
        );
        _updateSavingBalance(savingCtrl, oldDest, oldExp.amount, 'expense');
      } else {
        final revertType = oldExp.type == 'expense' ? 'income' : 'expense';
        _updateSavingBalance(
          savingCtrl,
          oldExp.source,
          oldExp.amount,
          revertType,
        );
      }
    }

    if (_selectedType == 'transfer') {
      _updateSavingBalance(savingCtrl, _selectedSource, amount, 'expense');
      _updateSavingBalance(savingCtrl, _selectedDestination, amount, 'income');
    } else {
      _updateSavingBalance(savingCtrl, _selectedSource, amount, _selectedType);
    }

    String finalNote = _noteController.text.trim();
    if (_selectedType == 'transfer')
      finalNote = "Dari $_selectedSource ke $_selectedDestination. $finalNote";

    if (widget.expenseToEdit != null) {
      final oldExp = widget.expenseToEdit!;
      oldExp.amount = amount;
      oldExp.category = _selectedCategory!;
      oldExp.note = finalNote;
      oldExp.date = _selectedDate;
      oldExp.type = _selectedType;
      oldExp.source = _selectedSource;
      oldExp.save();

      final index = expenseCtrl.expenses.indexOf(oldExp);
      if (index != -1) expenseCtrl.updateExpense(index, oldExp);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaksi diperbarui!')));
    } else {
      final expense = Expense(
        amount: amount,
        category: _selectedCategory!,
        note: finalNote,
        date: _selectedDate,
        type: _selectedType,
        source: _selectedSource,
      );
      expenseCtrl.addExpense(expense);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaksi disimpan!')));
    }

    Navigator.pop(context);
  }

  void _updateSavingBalance(
    SavingController ctrl,
    String accountName,
    double amount,
    String type,
  ) {
    if (accountName != 'Budget Utama') {
      try {
        final account = ctrl.savings.firstWhere((s) => s.name == accountName);
        ctrl.updateBalance(account, amount, type);
      } catch (_) {}
    }
  }
}
