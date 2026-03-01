import 'package:flutter/material.dart';
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

  const AddExpensePage({super.key, this.fixedDate});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense'; // 'expense', 'income', atau 'transfer'
  String? _selectedCategory;

  String _selectedSource = 'Budget Utama';
  String _selectedDestination = 'Budget Utama'; // Khusus untuk transfer

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.fixedDate ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCategoryList();
    });
  }

  void _updateCategoryList() {
    // Transfer tidak butuh list kategori
    if (_selectedType == 'transfer') {
      setState(() => _selectedCategory = 'Transfer');
      return;
    }

    final catController = context.read<CategoryController>();
    final categories = _selectedType == 'expense'
        ? catController.expenseCategories
        : catController.incomeCategories;

    if (categories.isNotEmpty) {
      setState(() => _selectedCategory = categories.first.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catController = context.watch<CategoryController>();
    final savingController = context.watch<SavingController>();

    final categories = _selectedType == 'expense'
        ? catController.expenseCategories
        : catController.incomeCategories;

    // Daftar sumber/tujuan dana
    final accountOptions = [
      'Budget Utama',
      ...savingController.savings.map((s) => s.name),
    ];

    // Pastikan _selectedDestination valid
    if (!accountOptions.contains(_selectedDestination)) {
      _selectedDestination = accountOptions.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 1. PEMILIHAN TIPE TRANSAKSI (3 OPSI)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTypeButton('Pengeluaran', 'expense', Colors.red),
                  _buildTypeButton('Pemasukan', 'income', Colors.green),
                  _buildTypeButton('Transfer', 'transfer', Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 2. NOMINAL
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                CurrencyInputFormatter(),
              ], // 👈 Tambahkan baris ini
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 3. KATEGORI (Sembunyikan jika Transfer)
            if (_selectedType != 'transfer') ...[
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 20),
            ],

            // 🔹 4. SUMBER DANA & TUJUAN DANA
            if (_selectedType == 'transfer') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blue.shade50,
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Dari (Sumber Dana)',
                        border: InputBorder.none,
                        icon: Icon(Icons.outbox, color: Colors.red),
                      ),
                      items: accountOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSource = val!),
                    ),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      value: _selectedDestination,
                      decoration: const InputDecoration(
                        labelText: 'Ke (Tujuan Dana)',
                        border: InputBorder.none,
                        icon: Icon(Icons.move_to_inbox, color: Colors.green),
                      ),
                      items: accountOptions
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDestination = val!),
                    ),
                  ],
                ),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: const InputDecoration(
                  labelText: 'Sumber / Tujuan Dana',
                  border: OutlineInputBorder(),
                ),
                items: accountOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSource = val!),
              ),
            ],

            const SizedBox(height: 20),

            // 🔹 5. TANGGAL (Terkunci jika dari History)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tanggal Transaksi',
                style: TextStyle(color: Colors.grey),
              ),
              subtitle: Text(
                DateFormat('EEEE, d MMMM y', 'id_ID').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.lock_clock, color: Colors.grey),
            ),
            const Divider(),

            // 🔹 6. CATATAN
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            // 🔹 7. TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'expense'
                      ? Colors.red
                      : (_selectedType == 'income'
                            ? Colors.green
                            : Colors.blue),
                ),
                onPressed: _handleSave,
                child: const Text(
                  'Simpan Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget custom untuk tombol tipe transaksi
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nominal harus diisi!')));
      return;
    }

    // final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final String cleanAmount = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final double amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) return;

    // Validasi khusus transfer: Sumber dan Tujuan tidak boleh sama
    if (_selectedType == 'transfer' &&
        _selectedSource == _selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sumber dan Tujuan dana tidak boleh sama!'),
        ),
      );
      return;
    }

    // Peringatan Budget (Hanya jalan jika pengeluaran & dari Budget Utama)
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
              (e) => e.category == _selectedCategory && e.type == 'expense',
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
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Peringatan Budget!'),
          ],
        ),
        content: Text(
          'Transaksi ini akan melebihi limit budget kategori $_selectedCategory.\n\n'
          'Sisa Budget: ${CurrencyInputFormatter.format(limit - alreadySpent)}\n\n'
          'Tetap lanjutkan simpan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

    // 🎯 LOGIKA UPDATE SALDO TABUNGAN
    if (_selectedType == 'transfer') {
      // 1. Potong dari sumber
      if (_selectedSource != 'Budget Utama') {
        try {
          final sourceAcc = savingCtrl.savings.firstWhere(
            (s) => s.name == _selectedSource,
          );
          savingCtrl.updateBalance(
            sourceAcc,
            amount,
            'expense',
          ); // Kurangi saldo
        } catch (_) {}
      }
      // 2. Tambah ke tujuan
      if (_selectedDestination != 'Budget Utama') {
        try {
          final destAcc = savingCtrl.savings.firstWhere(
            (s) => s.name == _selectedDestination,
          );
          savingCtrl.updateBalance(destAcc, amount, 'income'); // Tambah saldo
        } catch (_) {}
      }
    } else {
      // Logika normal (Pemasukan / Pengeluaran biasa)
      if (_selectedSource != 'Budget Utama') {
        try {
          final account = savingCtrl.savings.firstWhere(
            (s) => s.name == _selectedSource,
          );
          savingCtrl.updateBalance(account, amount, _selectedType);
        } catch (_) {}
      }
    }

    // 🎯 LOGIKA SIMPAN KE RIWAYAT (Expense)
    String finalNote = _noteController.text.trim();
    if (_selectedType == 'transfer') {
      finalNote = "Dari $_selectedSource ke $_selectedDestination. $finalNote";
    }

    final expense = Expense(
      amount: amount,
      category: _selectedCategory!, // Otomatis "Transfer" jika tipenya transfer
      note: finalNote,
      date: _selectedDate,
      type: _selectedType, // 'expense', 'income', atau 'transfer'
      source: _selectedSource,
    );

    context.read<ExpenseController>().addExpense(expense);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan!')),
    );
    Navigator.pop(context); // Kembali ke halaman sebelumnya
  }
}
