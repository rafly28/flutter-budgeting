import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../controllers/debt_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/saving_controller.dart';
import '../models/debt.dart';
import '../utils/currency_input_formatter.dart';

class AddDebtPage extends StatefulWidget {
  const AddDebtPage({super.key});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  String _selectedType = 'piutang';
  String _selectedAccount = 'Budget Utama';
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _amountController.text.isEmpty) {
      _showToast('Nama dan nominal wajib diisi.');
      return;
    }

    final cleanAmt = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amt = double.tryParse(cleanAmt) ?? 0.0;
    if (amt <= 0) {
      _showToast('Nominal harus lebih dari nol.');
      return;
    }

    final expenseController = context.read<ExpenseController>();
    if (_selectedType == 'piutang' &&
        amt > expenseController.balanceFor(_selectedAccount)) {
      _showToast('Saldo $_selectedAccount tidak mencukupi.');
      return;
    }

    final debt = Debt(
      type: _selectedType,
      personName: _nameController.text.trim(),
      amount: amt,
      createdAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    final saved = await context.read<DebtController>().addDebt(
      debt,
      _selectedAccount,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!saved) {
      _showToast('Catatan gagal disimpan. Periksa akun dan saldo.');
      return;
    }

    toastification.show(
      context: context,
      title: const Text('Catatan berhasil disimpan.'),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
    );
    Navigator.pop(context);
  }

  void _showToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savings = context.watch<SavingController>().savings;
    final expenseController = context.watch<ExpenseController>();
    final accountOptions = [
      'Budget Utama',
      ...savings.map((account) => account.name),
    ];
    if (!accountOptions.contains(_selectedAccount)) {
      _selectedAccount = 'Budget Utama';
    }
    final accountBalance = expenseController.balanceFor(_selectedAccount);
    final accountLabel = _selectedType == 'piutang'
        ? 'Dari (Sumber Dana)'
        : 'Ke (Tujuan Dana)';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Catat Hutang/Piutang",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Jenis Catatan",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildTypeBtn("Piutang", 'piutang', Colors.green),
                            const SizedBox(width: 10),
                            _buildTypeBtn("Hutang", 'hutang', Colors.red),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Nama Orang",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
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
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Nominal",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          accountLabel,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedAccount),
                          initialValue: _selectedAccount,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: accountOptions
                              .map(
                                (account) => DropdownMenuItem(
                                  value: account,
                                  child: Text(
                                    account,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (account) {
                            if (account != null) {
                              setState(() => _selectedAccount = account);
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Saldo: ${CurrencyInputFormatter.format(accountBalance)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              _isSaving ? "Menyimpan..." : "Simpan Catatan",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBtn(String label, String val, Color color) {
    bool isSel = _selectedType == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? color : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? color : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
