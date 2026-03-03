import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/user_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_input_formatter.dart';
import 'category_management_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final budgetController = context.watch<BudgetController>();
    final categoryController = context.watch<CategoryController>();

    final userName = userController.user?.name ?? 'User';
    final payday = userController.payday;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Pengaturan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                bottom: 30,
                top: 10,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sistem",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.person_outline,
                            color: Colors.blue.shade700,
                          ),
                          title: const Text("Nama Panggilan"),
                          subtitle: Text(userName),
                          trailing: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onTap: () => _showEditNameDialog(
                            context,
                            userController,
                            userName,
                          ),
                        ),
                        const Divider(height: 1, indent: 50, endIndent: 16),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.blue.shade700,
                          ),
                          title: const Text("Tanggal Gajian (Siklus)"),
                          subtitle: Text("Tanggal $payday setiap bulan"),
                          trailing: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onTap: () => _showEditPaydayDialog(
                            context,
                            userController,
                            payday,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Anggaran & Kategori",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.track_changes_outlined,
                            color: Colors.red.shade400,
                          ),
                          title: const Text("Atur Limit Budget"),
                          subtitle: const Text(
                            "Batas pengeluaran per kategori",
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () => _showBudgetListBottomSheet(
                            context,
                            categoryController,
                            budgetController,
                          ),
                        ),
                        const Divider(height: 1, indent: 50, endIndent: 16),
                        ListTile(
                          leading: Icon(
                            Icons.category_outlined,
                            color: Colors.orange.shade400,
                          ),
                          title: const Text("Kelola Kategori"),
                          subtitle: const Text("Tambah / hapus kategori"),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryManagementPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    UserController controller,
    String currentName,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ubah Nama"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Nama Baru"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                controller.setUser(nameCtrl.text); // 👈 Memanggil setUser
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPaydayDialog(
    BuildContext context,
    UserController controller,
    int currentPayday,
  ) {
    int selectedDay = currentPayday;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Siklus Bulanan (Gajian)"),
        content: DropdownButtonFormField<int>(
          value: selectedDay,
          decoration: const InputDecoration(labelText: "Pilih Tanggal"),
          items: List.generate(
            28,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text("Tanggal ${index + 1}"),
            ),
          ),
          onChanged: (val) => selectedDay = val ?? currentPayday,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              controller.setPayday(selectedDay); // 👈 Memanggil setPayday
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBudgetListBottomSheet(
    BuildContext context,
    CategoryController catCtrl,
    BudgetController budgetCtrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Limit Budget per Kategori",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Consumer<BudgetController>(
                  builder: (context, currentBudgetCtrl, child) {
                    final categories = catCtrl.expenseCategories;
                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final catName = categories[index].name;
                        final limit = currentBudgetCtrl.getBudgetLimit(catName);
                        return ListTile(
                          title: Text(
                            catName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            limit > 0
                                ? "Limit: ${CurrencyInputFormatter.format(limit)}"
                                : "Belum diatur",
                            style: TextStyle(
                              color: limit > 0 ? Colors.red : Colors.grey,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _showSetBudgetDialog(
                              context,
                              catName,
                              limit,
                              currentBudgetCtrl,
                            ),
                            child: Text(limit > 0 ? "Edit" : "Atur"),
                          ),
                        );
                      },
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
    final initialText = currentLimit > 0
        ? NumberFormat.decimalPattern("id_ID").format(currentLimit.toInt())
        : "";
    final amountController = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Limit: $category"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
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
              final String cleanAmount = amountController.text.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              controller.setBudgetLimit(
                category,
                double.tryParse(cleanAmount) ?? 0.0,
              );
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
