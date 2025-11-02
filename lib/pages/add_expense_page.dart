import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class AddExpensePage extends StatefulWidget {
  final DateTime? initialDate; // 🔹 bisa kirim tanggal dari luar (misal dari HistoryPage)

  const AddExpensePage({super.key, this.initialDate});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedCategory = "Umum";
  String _type = "expense"; // default: pengeluaran
  late DateTime _selectedDate;

  final List<String> _categories = [
    "Makanan",
    "Transportasi",
    "Belanja",
    "Hiburan",
    "Tagihan",
    "Umum",
  ];

  @override
  void initState() {
    super.initState();
    // 🔹 Gunakan tanggal yang dikirim dari luar, jika ada (misal dari HistoryPage)
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Transaksi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
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
                value: _selectedCategory,
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

              // Catatan
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Catatan (opsional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Pilih tanggal transaksi
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Tanggal Transaksi"),
                subtitle: Text(
                  "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
                      lastDate: DateTime.now(),
                      locale: const Locale("id", "ID"),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final amount = double.tryParse(raw) ?? 0;

                      final newExpense = Expense(
                        amount: amount,
                        category: _selectedCategory,
                        note: _noteController.text.trim(),
                        date: _selectedDate,
                        type: _type,
                      );

                      context.read<ExpenseController>().addExpense(newExpense);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
