import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = "Umum";
  String _type = "expense"; // default: pengeluaran
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    "Makanan",
    "Transportasi",
    "Belanja",
    "Hiburan",
    "Tagihan",
    "Umum",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Transaksi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input jumlah uang
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Jumlah",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Masukkan jumlah";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pilihan tipe transaksi
              ToggleButtons(
                isSelected: [_type == "income", _type == "expense"],
                onPressed: (index) {
                  setState(() {
                    _type = index == 0 ? "income" : "expense";
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Pemasukan"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Pengeluaran"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown kategori
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Catatan",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // 🔹 Parsing nilai dari controller -> double
                      final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final amount = double.tryParse(raw) ?? 0;

                      final newExpense = Expense(
                        amount: amount,
                        category: _selectedCategory,
                        note: _noteController.text,
                        date: _selectedDate,
                        type: _type,
                      );

                      context.read<ExpenseController>().addExpense(newExpense);

                      Navigator.pop(context); // balik ke dashboard
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
