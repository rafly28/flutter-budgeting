import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

import '../controllers/expense_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../controllers/saving_controller.dart';
import '../controllers/plan_controller.dart';
import '../controllers/debt_controller.dart';
import '../controllers/user_controller.dart';
import '../models/expense.dart';
import '../models/plan_item.dart';
import '../models/debt.dart';
import '../models/saving_account.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/payday_cycle.dart';

class AddExpensePage extends StatefulWidget {
  final DateTime? fixedDate;
  final Expense? expenseToEdit;
  final PlanItem? planToPay;
  final String? savingDestination;

  const AddExpensePage({super.key, this.fixedDate, this.expenseToEdit, this.planToPay, this.savingDestination});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedType = 'expense';
  String _debtType = 'piutang';
  String? _selectedCategory;

  /// True kalau kategori asli transaksi sudah tidak ada (kategori dihapus
  /// atau di-rename). Kategori tidak diganti diam-diam; pengguna memilih
  /// sendiri supaya transaksi tidak salah filed.
  bool _isOriginalCategoryMissing = false;
  String _selectedSource = 'Budget Utama';
  String _selectedDestination = 'Budget Utama';

  late DateTime _selectedDate;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

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
    } else if (widget.planToPay != null) {
      final plan = widget.planToPay!;
      _amountController.text = NumberFormat.decimalPattern("id_ID").format(plan.amount.toInt());
      if (plan.planType == 'saving') {
        _selectedType = 'transfer';
        _selectedSource = 'Budget Utama';
        _selectedDestination = plan.category; // Category contains the saving account name
        _noteController.text = plan.title;
      } else {
        _selectedType = 'expense';
        _selectedCategory = plan.category;
        _noteController.text = plan.title;
      }
      _selectedDate = widget.fixedDate ?? DateTime.now();
    } else if (widget.savingDestination != null) {
      _selectedType = 'transfer';
      _selectedSource = 'Budget Utama';
      _selectedDestination = widget.savingDestination!;
      _selectedDate = widget.fixedDate ?? DateTime.now();
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
    if (_selectedType == 'debt') {
      setState(() => _selectedCategory = 'Debt');
      return;
    }
    final catController = context.read<CategoryController>();
    final categories = _selectedType == 'expense'
        ? catController.expenseCategories
        : catController.incomeCategories;

    if (categories.isNotEmpty) {
      setState(() {
        final isMissing = !categories.any(
          (c) => c.name == _selectedCategory,
        );
        // Kategori lama yang sudah dihapus/rename tidak boleh diam-diam
        // pindah ke kategori pertama — pemakai harus melihat danmemilih
        // sendiri supaya transaksi tidak salah filed.
        if (widget.expenseToEdit != null && isMissing) {
          _isOriginalCategoryMissing = true;
          return;
        }
        if (widget.expenseToEdit == null && widget.planToPay == null ||
            isMissing) {
          _selectedCategory = categories.first.name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catController = context.watch<CategoryController>();
    final savingController = context.watch<SavingController>();
    final expenseController = context.watch<ExpenseController>();

    final categories = _selectedType == 'expense'
        ? catController.expenseCategories
        : catController.incomeCategories;
    final accountOptions = [
      'Budget Utama',
      ...savingController.savings.map((s) => s.name),
    ];

    if (!accountOptions.contains(_selectedDestination)) {
      _selectedDestination = accountOptions.first;
    }
    if (!accountOptions.contains(_selectedSource)) {
      _selectedSource = accountOptions.first;
    }
    
    // Akun investasi menampilkan nilai pasar, karena itu yang benar-benar
    // tersedia saat ditarik.
    double balanceOf(String accountName) => accountName == 'Budget Utama'
        ? expenseController.balanceFor('Budget Utama', at: _selectedDate)
        : (savingController.savings
                  .where((s) => s.name == accountName)
                  .firstOrNull
                  ?.marketValue ??
              0.0);

    final double sourceBalance = balanceOf(_selectedSource);
    final double destBalance = balanceOf(_selectedDestination);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tanggal Transaksi",
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
            ),
            Text(
              DateFormat('EEEE, d MMMM y', 'id_ID').format(_selectedDate),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
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
                color: Theme.of(context).colorScheme.primary,
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
                          color: Colors.grey.shade50,
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
                            if (widget.expenseToEdit == null &&
                                widget.planToPay == null &&
                                widget.savingDestination == null)
                              _buildTypeButton(
                                'Hutang',
                                'debt',
                                Colors.orange,
                              ),
                          ],
                        ),
                      ),
                      if (_selectedType == 'debt') ...[
                        const SizedBox(height: 18),
                        const Text(
                          "Jenis Catatan",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _debtType = 'piutang'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _debtType == 'piutang' ? Colors.green : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _debtType == 'piutang' ? Colors.green : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    'Piutang',
                                    style: TextStyle(
                                      color: _debtType == 'piutang' ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _debtType = 'hutang'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _debtType == 'hutang' ? Colors.red : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _debtType == 'hutang' ? Colors.red : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    'Hutang',
                                    style: TextStyle(
                                      color: _debtType == 'hutang' ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "Nama Orang",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Cth: Budi",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
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
                      if (_selectedType != 'transfer' && _selectedType != 'debt') ...[
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
                          key: ValueKey('cat_$_selectedCategory'),
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            isDense: true, // 👈 Membuat dropdown lebih compact
                            filled: true,
                            fillColor: _isOriginalCategoryMissing
                                ? Colors.amber.shade50
                                : Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            // Kategori lama yang sudah hilang tetap
                            // ditampilkan supaya pengguna tahu asal-usulnya,
                            // tapi tidak bisa dipilih lagi.
                            if (_isOriginalCategoryMissing &&
                                _selectedCategory != null &&
                                !categories.any(
                                  (c) => c.name == _selectedCategory,
                                ))
                              DropdownMenuItem(
                                value: _selectedCategory,
                                enabled: false,
                                child: Text(
                                  '⚠ ${_selectedCategory} (tidak ada lagi)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ...categories.map(
                              (c) => DropdownMenuItem(
                                value: c.name,
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() {
                            _selectedCategory = val;
                            _isOriginalCategoryMissing = false;
                          }),
                        ),
                        if (_isOriginalCategoryMissing)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Kategori asli transaksi ini sudah tidak ada. '
                              'Pilih kategori baru agar tidak salah report.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        const SizedBox(height: 15), // 👈 Dirapatkan
                      ],

                      // 🔹 4. SUMBER DANA & TUJUAN DANA
                      if (_selectedType == 'transfer') ...[
                        Container(
                          padding: const EdgeInsets.all(12), // 👈 Dirapatkan
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                                key: ValueKey('src_$_selectedSource'),
                                initialValue: _selectedSource,
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
                              const SizedBox(height: 4),
                              Text(
                                "Saldo: ${CurrencyInputFormatter.format(sourceBalance)}",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                key: ValueKey('dst_$_selectedDestination'),
                                initialValue: _selectedDestination,
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
                              const SizedBox(height: 4),
                              Text(
                                "Saldo: ${CurrencyInputFormatter.format(destBalance)}",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedType == 'transfer')
                                _InvestmentPreview(
                                  source: _selectedSource,
                                  destination: _selectedDestination,
                                  amountController: _amountController,
                                ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          _selectedType == 'debt' 
                              ? (_debtType == 'piutang' ? "Dari (Sumber Dana)" : "Ke (Tujuan Dana)")
                              : "Sumber / Tujuan Dana",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey('src_$_selectedSource'),
                          initialValue: _selectedSource,
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
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            "Saldo: ${CurrencyInputFormatter.format(sourceBalance)}",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 15), // 👈 Dirapatkan
                      // 🔹 5. CATATAN
                      if (_selectedType != 'debt') ...[
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
                      ],

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
                                      : (_selectedType == 'transfer' ? Colors.blue.shade600 : Colors.orange.shade600)),
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

  /// Nominal dari field input, sudah dibersihkan dari pemisah ribuan.
  double _parseAmount() {
    final clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  Future<void> _handleSave() async {
    if (_amountController.text.isEmpty) return;
    if (_selectedType != 'debt' && _selectedCategory == null) return;

    final double amount = _parseAmount();
    if (amount <= 0) return;

    if (_selectedType == 'debt') {
      return _saveDebt(amount);
    }

    if (_selectedType == 'transfer' &&
        _selectedSource == _selectedDestination) {
      toastification.show(
        context: context,
        title: const Text('Sumber dan Tujuan tidak boleh sama!'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    
    // Validasi saldo
    if (_selectedType == 'transfer' || _selectedType == 'expense') {
      final expenseController = context.read<ExpenseController>();
      final sourceBal = expenseController.balanceFor(_selectedSource, at: _selectedDate);
      final effectiveBal = _balanceAfterRevertingOld(
        _selectedSource,
        sourceBal,
      );

      if (amount > effectiveBal) {
        toastification.show(
          context: context,
          title: Text('Saldo $_selectedSource tidak mencukupi!'),
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
    }

    if (_selectedType == 'expense' && _selectedSource == 'Budget Utama') {
      final budgetController = context.read<BudgetController>();
      final expenseController = context.read<ExpenseController>();
      final userController = context.read<UserController>();
      double limit = budgetController.getBudgetLimit(_selectedCategory!);

      if (limit > 0) {
        final payday = userController.payday;
        final cycle = PaydayCycle.of(_selectedDate, payday);
        final cycleExpenses = expenseController.getExpensesByDateRange(
          cycle.start,
          cycle.end,
        );
        double alreadySpent = cycleExpenses
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

    await _saveData(amount);
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
            onPressed: () async {
              Navigator.pop(context);
              await _saveData(newAmount);
            },
            child: const Text(
              'Tetap Simpan'
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveData(double amount) async {
    final expenseCtrl = context.read<ExpenseController>();

    String finalNote = _noteController.text.trim();
    if (_selectedType == 'transfer') {
      finalNote = "Dari $_selectedSource ke $_selectedDestination. $finalNote";
    }
    // Tujuan transfer disimpan sebagai data, bukan cuma di dalam note, supaya
    // nama rekening yang mengandung titik tetap bisa dibaca.
    final String? transferDestination = _selectedType == 'transfer'
        ? _selectedDestination
        : null;

    if (widget.expenseToEdit != null) {
      final oldExp = widget.expenseToEdit!;
      final updatedExpense = Expense(
        amount: amount,
        category: _selectedCategory!,
        note: finalNote,
        date: _selectedDate,
        type: _selectedType,
        source: _selectedSource,
        planId: oldExp.planId,
        debtId: oldExp.debtId,
        transferDestination: transferDestination,
      );
      final updated = await expenseCtrl.updateExpense(
        oldExp,
        updatedExpense,
      );
      if (!mounted) return;
      if (!updated) {
        _showSaveError(expenseCtrl.lastFailureReason);
        return;
      }

      toastification.show(
        context: context,
        title: const Text('Transaksi diperbarui!'),
        type: ToastificationType.success,
        style: ToastificationStyle.flat,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } else {
      final expense = Expense(
        amount: amount,
        category: _selectedCategory!,
        note: finalNote,
        date: _selectedDate,
        type: _selectedType,
        source: _selectedSource,
        planId: widget.planToPay?.id,
        transferDestination: transferDestination,
      );
      final added = await expenseCtrl.addExpense(expense);
      if (!mounted) return;
      if (!added) {
        _showSaveError(expenseCtrl.lastFailureReason);
        return;
      }
      
      // Jika dari Planning, tandai sebagai sudah dibayar
      if (widget.planToPay != null) {
        final planCtrl = context.read<PlanController>();
        final plan = widget.planToPay!;
        plan.isPaid = true;
        // key bisa null kalau box-nya sudah diganti (mis. setelah restore).
        // Menulis dengan key null akan membuat plan tersimpan di key tak
        // bernama, jadi dilewati saja — transaksinya sudah tercatat.
        if (plan.key != null) {
          plan.save();
          planCtrl.updatePlanByKey(plan.key, plan);
        } else {
          planCtrl.refresh();
        }
      }
      
      toastification.show(
        context: context,
        title: const Text('Transaksi disimpan!'),
        type: ToastificationType.success,
        style: ToastificationStyle.flat,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  double _balanceAfterRevertingOld(String accountName, double currentBalance) {
    final oldExp = widget.expenseToEdit;
    if (oldExp == null) return currentBalance;

    var balance = currentBalance;
    if (oldExp.source == accountName) {
      if (oldExp.type == 'income') {
        balance -= oldExp.amount;
      } else {
        balance += oldExp.amount;
      }
    }

    if (oldExp.type == 'transfer' &&
        _transferDestination(oldExp.note) == accountName) {
      balance -= oldExp.amount;
    }
    return balance;
  }

  String? _transferDestination(String? note) {
    if (note == null || !note.startsWith('Dari ')) return null;
    final firstDot = note.indexOf('.');
    if (firstDot == -1) return null;
    final parts = note.substring(0, firstDot).split(' ke ');
    return parts.length > 1 ? parts[1] : null;
  }

  void _showSaveError([String? reason]) {
    final fallback =
        'Transaksi gagal disimpan karena akun terkait tidak ditemukan.';
    toastification.show(
      context: context,
      title: Text(reason ?? fallback),
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  Future<void> _saveDebt(double amount) async {
    if (_nameController.text.trim().isEmpty) {
      toastification.show(
        context: context,
        title: const Text('Nama wajib diisi.'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    final expenseController = context.read<ExpenseController>();
    if (_debtType == 'piutang' &&
        amount > expenseController.balanceFor(_selectedSource, at: _selectedDate)) {
      toastification.show(
        context: context,
        title: Text('Saldo $_selectedSource tidak mencukupi.'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    // Need to import DebtController and Debt at the top. Wait, they are imported?
    // Let's check imports.
    final debt = Debt(
      type: _debtType,
      personName: _nameController.text.trim(),
      amount: amount,
      createdAt: _selectedDate,
    );

    final saved = await context.read<DebtController>().addDebt(
      debt,
      _selectedSource,
    );
    if (!mounted) return;

    if (!saved) {
      toastification.show(
        context: context,
        title: const Text('Catatan gagal disimpan. Periksa akun dan saldo.'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    toastification.show(
      context: context,
      title: const Text('Catatan berhasil disimpan.'),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
    );
    Navigator.pop(context, true);
  }
}

/// Pratinjau konversi rupiah ke unit untuk transfer yang menyentuh aset
/// investasi.
///
/// Menampilkan harga yang benar-benar dipakai: harga jual toko saat membeli,
/// harga buyback saat menjual. Tanpa ini pengguna tidak tahu berapa gram
/// yang akan ditambahkan atau mengurangi saldonya.
class _InvestmentPreview extends StatelessWidget {
  final String source;
  final String destination;
  final TextEditingController amountController;

  const _InvestmentPreview({
    required this.source,
    required this.destination,
    required this.amountController,
  });

  double get _amount {
    final clean = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Nominal dipratinjau ulang tiap ketikan, jadi user melihat jumlah unit
    // yang akan ditambahkan atau berkurang sebelum menekan simpan.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: amountController,
      builder: (context, _, __) => _buildPreview(context, _amount),
    );
  }

  Widget _buildPreview(BuildContext context, double amount) {
    final savingController = context.watch<SavingController>();

    SavingAccount? incoming;
    SavingAccount? outgoing;
    if (source != 'Budget Utama') {
      final account = _find(savingController, source);
      if (account != null && account.isInvestment) outgoing = account;
    }
    if (destination != 'Budget Utama') {
      final account = _find(savingController, destination);
      if (account != null && account.isInvestment) incoming = account;
    }
    if (incoming == null && outgoing == null) return const SizedBox.shrink();

    final target = incoming ?? outgoing!;
    final isBuying = incoming != null;
    final price = savingController.conversionPriceFor(
      target,
      incoming: isBuying,
    );
    final theme = Theme.of(context);

    if (price == null || price <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Harga ${target.name} belum tersedia. Refresh harga di '
                'halaman Tabungan sebelum transfer.',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final units = amount / price;
    final priceLabel = isBuying ? 'harga jual' : 'harga buyback';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isBuying
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isBuying ? Colors.green : Colors.orange).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBuying ? Icons.add_circle : Icons.remove_circle,
            size: 18,
            color: isBuying ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                amount <= 0
                    ? '${isBuying ? 'Akan menambah' : 'Akan mengurangi'} '
                          '${target.name}'
                    : '${isBuying ? 'Menambah' : 'Mengurang'} '
                          '${_formatUnits(units, target.effectiveUnitLabel)} '
                          '${target.name} @ '
                          '${CurrencyInputFormatter.format(price)}/$priceLabel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ),
        ],
      ),
    );
  }

  SavingAccount? _find(SavingController controller, String name) {
    for (final account in controller.savings) {
      if (account.name == name) return account;
    }
    return null;
  }
}

/// "0,39 gram" — jumlah unit sesuai format Indonesia.
String _formatUnits(double count, String unit) {
  final formatted = NumberFormat('#,##0.###', 'id_ID').format(count);
  return unit.isEmpty ? formatted : '$formatted $unit';
}
