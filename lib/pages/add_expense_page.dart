import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/expense_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../controllers/saving_controller.dart'; // Jika belum ada error abaikan saja, atau hapus jika belum buat controller tabungan
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategory;
  String _selectedSource = 'Budget Utama';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Inisialisasi kategori pertama kali render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCategoryList();
    });
  }

  void _updateCategoryList() {
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

    // Persiapkan daftar sumber dana (Budget Utama + Semua Tabungan)
    final sourceOptions = [
      'Budget Utama',
      ...savingController.savings.map((s) => s.name),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tipe Transaksi (Pemasukan / Pengeluaran)
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(
                      'Pengeluaran',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'expense',
                    groupValue: _selectedType,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val!;
                        _updateCategoryList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(
                      'Pemasukan',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'income',
                    groupValue: _selectedType,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val!;
                        _updateCategoryList();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. Nominal
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Dropdown Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(value: c.name, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            // 4. Dropdown Sumber Dana (Budget Utama / Tabungan)
            DropdownButtonFormField<String>(
              value: _selectedSource,
              decoration: const InputDecoration(
                labelText: 'Sumber Dana',
                border: OutlineInputBorder(),
              ),
              items: sourceOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSource = val!),
            ),
            const SizedBox(height: 20),

            // 5. Tanggal
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal'),
              subtitle: Text(
                DateFormat('d MMMM y', 'id_ID').format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const Divider(),

            // 6. Catatan Tambahan
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            // 7. Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text(
                  'Simpan Transaksi',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal dan Kategori harus diisi!')),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    // 🎯 LOGIKA PERINGATAN BUDGET (Hanya jalan jika pengeluaran & dari Budget Utama)
    if (_selectedType == 'expense' && _selectedSource == 'Budget Utama') {
      final budgetController = context.read<BudgetController>();
      final expenseController = context.read<ExpenseController>();

      double limit = budgetController.getBudgetLimit(_selectedCategory!);

      if (limit > 0) {
        // Hitung pengeluaran kategori ini di bulan ini
        final currentMonthExpenses = expenseController.getExpensesByMonth(
          _selectedDate.year,
          _selectedDate.month,
        );
        double alreadySpent = currentMonthExpenses
            .where(
              (e) => e.category == _selectedCategory && e.type == 'expense',
            )
            .fold(0.0, (s, e) => s + e.amount);

        // Jika setelah ditambah transaksi ini akan jebol
        if ((alreadySpent + amount) > limit) {
          _showBudgetWarningDialog(amount, limit, alreadySpent);
          return; // Hentikan eksekusi, tunggu konfirmasi user
        }
      }
    }

    // Jika aman, langsung simpan
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
          'Transaksi ini akan membuat Anda melebihi limit budget untuk kategori $_selectedCategory.\n\n'
          'Limit: ${CurrencyInputFormatter.format(limit)}\n'
          'Sudah Terpakai: ${CurrencyInputFormatter.format(alreadySpent)}\n'
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
              Navigator.pop(context); // Tutup dialog
              _saveData(newAmount); // Lanjutkan simpan
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
    final expense = Expense(
      amount: amount,
      category: _selectedCategory!,
      note: _noteController.text.trim(),
      date: _selectedDate,
      type: _selectedType,
      source: _selectedSource,
    );

    // 1. Simpan ke riwayat transaksi
    context.read<ExpenseController>().addExpense(expense);

    // 2. Jika sumber dananya dari Tabungan, potong/tambah saldo tabungannya
    if (_selectedSource != 'Budget Utama') {
      final savingCtrl = context.read<SavingController>();
      try {
        final account = savingCtrl.savings.firstWhere(
          (s) => s.name == _selectedSource,
        );
        savingCtrl.updateBalance(account, amount, _selectedType);
      } catch (e) {
        // Tabungan tidak ditemukan (error handling aman)
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan!')),
    );
    Navigator.pop(context); // Kembali ke Dashboard
  }
}
