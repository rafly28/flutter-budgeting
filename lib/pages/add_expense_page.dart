import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import untuk memformat tanggal
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class AddExpensePage extends StatefulWidget {
  final DateTime? initialDate; 
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

  // 🚩 Kategori Terpisah untuk Pemasukan dan Pengeluaran
  final List<String> _expenseCategories = [
    "Makanan",
    "Transportasi",
    "Belanja",
    "Hiburan",
    "Tagihan",
    "Umum",
  ];

  final List<String> _incomeCategories = [
    "Gaji",
    "Investasi",
    "Hadiah",
    "Lain-lain",
  ];

  // Getter dinamis untuk mendapatkan daftar kategori saat ini
  List<String> get _currentCategories => 
      _type == "income" ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    // Inisialisasi kategori awal dari daftar Pengeluaran (default)
    _selectedCategory = _expenseCategories.first; 
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan warna utama berdasarkan tipe transaksi
    Color primaryColor = _type == "income" ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Transaksi")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
                ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: primaryColor),
                title: const Text("Tanggal Transaksi"),
                subtitle: Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                      .format(_selectedDate),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor),
                ),
                onTap: () => _selectDate(context),
              ),
              const Divider(),
              const SizedBox(height: 5),
              // 1. Tipe Transaksi (Income/Expense) - Dibuat lebih visual
              Row(
                children: [
                  _buildTypeButton(
                      context, "Pemasukan", "income", Colors.green),
                  const SizedBox(width: 12),
                  _buildTypeButton(
                      context, "Pengeluaran", "expense", Colors.red),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Input Jumlah Uang - Dibuat lebih besar/menarik
              TextFormField(
                controller: _amountController,
                inputFormatters: [CurrencyInputFormatter()],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center, // Center text
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                decoration: InputDecoration(
                  hintText: "0",
                  labelText: "Jumlah", // Dikembalikan atas permintaan user
                  prefixText: "Rp ",
                  prefixStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: primaryColor.withOpacity(0.5), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  // Mengatur padding kiri agar labelText tidak mepet ke pinggir
                  contentPadding: const EdgeInsets.fromLTRB(40, 20, 20, 20),
                ),
                validator: (value) {
                  final raw = value?.replaceAll(RegExp(r'[^0-9]'), '');
                  if (raw == null || raw.isEmpty || raw == '0') {
                    return "Masukkan jumlah yang valid";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // 4. Dropdown kategori - Menggunakan daftar kategori yang dinamis
              DropdownButtonFormField<String>(
                // Memastikan nilai awal ada dalam daftar kategori saat ini
                initialValue: _currentCategories.contains(_selectedCategory)
                    ? _selectedCategory
                    : _currentCategories.first,
                decoration: InputDecoration(
                  labelText: "Kategori",
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  prefixIcon: Icon(Icons.category, color: primaryColor),
                ),
                items: _currentCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 10),

              // 5. Catatan
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: "Catatan (opsional)",
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  prefixIcon: Icon(Icons.note, color: primaryColor),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              // 6. Tombol simpan - Menggunakan warna dinamis
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: const Text("SIMPAN TRANSAKSI",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Logic penyimpanan (tidak diubah)
                    if (_formKey.currentState!.validate()) {
                      final raw = _amountController.text
                          .replaceAll(RegExp(r'[^0-9]'), '');
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

  // Helper Widget untuk Tombol Pilihan Tipe Transaksi
  Widget _buildTypeButton(
      BuildContext context, String title, String type, Color color) {
    bool isSelected = _type == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _type = type;
            // 🚩 Reset kategori ke nilai default saat tipe berubah
            _selectedCategory = _currentCategories.first;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                type == "income" ? Icons.wallet : Icons.shopping_bag,
                color: isSelected ? color : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
