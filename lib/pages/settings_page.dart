import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/user_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_input_formatter.dart';
import 'category_management_page.dart';
import 'saving_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // 1. Menu Atur Tanggal Tutup Buku
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: const Text('Atur Tanggal Tutup Buku'),
            subtitle: Text('Siklus saat ini: Tanggal ${userController.payday}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPaydaySettings(context, userController),
          ),
          const Divider(height: 1),

          // 2. Menu Kelola Kategori
          ListTile(
            leading: const Icon(Icons.category, color: Colors.orange),
            title: const Text('Kelola Kategori'),
            subtitle: const Text('Tambah, edit, atau hapus kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),

          // 👇 3. MENU BARU: ATUR LIMIT BUDGET
          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
            ),
            title: const Text('Atur Limit Budget'),
            subtitle: const Text('Tetapkan batas maksimal pengeluaran bulanan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBudgetListBottomSheet(context),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.savings, color: Colors.blueAccent),
            title: const Text('Kelola Tabungan'),
            subtitle: const Text('Tambah rekening atau dompet tabungan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavingsPage()),
              );
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _showPaydaySettings(
    BuildContext context,
    UserController userController,
  ) {
    int tempPayday = userController.payday;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Atur Tanggal Tutup Buku"),
          content: DropdownButton<int>(
            value: tempPayday,
            isExpanded: true,
            items: List.generate(28, (index) => index + 1)
                .map(
                  (e) => DropdownMenuItem(value: e, child: Text("Tanggal $e")),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setDialogState(() => tempPayday = val);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                userController.setPayday(tempPayday);
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 FUNGSI BARU: Menampilkan daftar kategori pengeluaran untuk diatur limitnya
  void _showBudgetListBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categoryController = context.watch<CategoryController>();
        final budgetController = context.watch<BudgetController>();
        final expenseCategories = categoryController.expenseCategories;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Atur Limit Budget",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: expenseCategories.length,
                  itemBuilder: (context, index) {
                    final category = expenseCategories[index].name;
                    final limit = budgetController.getBudgetLimit(category);
                    return ListTile(
                      title: Text(category),
                      subtitle: Text(
                        limit > 0
                            ? CurrencyInputFormatter.format(limit)
                            : "Belum diatur",
                      ),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: () => _showSetBudgetDialog(
                        context,
                        category,
                        limit,
                        budgetController,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    String category,
    double currentLimit,
    BudgetController controller,
  ) {
    final amountController = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toInt().toString() : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Limit: $category"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Maksimal (Rp)",
            prefixText: "Rp ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              double newLimit = double.tryParse(amountController.text) ?? 0.0;
              controller.setBudgetLimit(category, newLimit);
              Navigator.pop(context); // Tutup dialog input
              Navigator.pop(context); // Tutup bottom sheet agar UI refresh
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
