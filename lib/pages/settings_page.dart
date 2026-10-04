import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../controllers/user_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_input_formatter.dart';
import 'category_management_page.dart';
import '../services/backup_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final budgetController = context.watch<BudgetController>();
    final categoryController = context.watch<CategoryController>();

    final userName = userController.user?.name ?? 'User';
    final payday = userController.payday;
    final resetBalance = userController.resetBalanceOnPayday;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.primary,
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
                        const Divider(height: 1, indent: 50, endIndent: 16),
                        SwitchListTile(
                          secondary: Icon(
                            Icons.refresh_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Mode Saldo: Reset Tiap Gajian"),
                          subtitle: const Text("Aktifkan jika ingin saldo di-reset jadi 0 tiap tanggal gajian."),
                          value: resetBalance,
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            userController.toggleResetBalance(val);
                          },
                        ),
                        const Divider(height: 1, indent: 50, endIndent: 16),
                        SwitchListTile(
                          secondary: Icon(
                            Icons.pie_chart_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text("Metode Anggaran 50-30-20"),
                          subtitle: const Text("Bagi pos belanja & tabungan jadi Kebutuhan (50%), Keinginan (30%), dan Tabungan (20%)."),
                          value: userController.budgetingMode == 'pocket_50_30_20',
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            userController.setBudgetingMode(val ? 'pocket_50_30_20' : 'standard');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 🔹 BAGIAN TEMA APLIKASI
                  const Text(
                    "Personalisasi Aplikasi",
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Warna Dasar",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 15,
                            runSpacing: 15,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildColorOption(context, userController, 0xFF1E3A8A, "Biru Gelap"),
                              _buildColorOption(context, userController, 0xFF0F172A, "Gelap"),
                              _buildColorOption(context, userController, 0xFFE11D48, "Pink"),
                              _buildColorOption(context, userController, 0xFF38BDF8, "Light Blue"),
                              _buildColorOption(context, userController, 0xFFFFB6C1, "Baby Pink"),
                              _buildColorOption(context, userController, 0xFFDDA0DD, "Plum"),
                              _buildColorOption(context, userController, 0xFFFFDAB9, "Peach"),
                              _buildColorOption(context, userController, 0xFFE0FFFF, "Baby Blue"),
                            ],
                          ),
                        ],
                      ),
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
                  const SizedBox(height: 20),
                  const Text(
                    "Data & Keamanan",
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
                          leading: const Icon(
                            Icons.backup_outlined,
                            color: Colors.blue,
                          ),
                          title: const Text("Backup Data"),
                          subtitle: const Text("Simpan data ke File Manager"),
                          onTap: () => BackupService.exportBackup(context),
                        ),
                        const Divider(height: 1, indent: 50, endIndent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.restore_outlined,
                            color: Colors.green,
                          ),
                          title: const Text("Restore Data"),
                          subtitle: const Text("Impor data dari file backup"),
                          onTap: () async {
                            bool success = await BackupService.importBackup();
                            if (success) {
                              toastification.show(
                                context: context,
                                title: const Text("✅ Restore Berhasil! Restart aplikasi."),
                                type: ToastificationType.success,
                                style: ToastificationStyle.flat,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Notifikasi",
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
                    child: SwitchListTile(
                      secondary: Icon(
                        userController.isNotificationEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        color: userController.isNotificationEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      title: const Text(
                        "Pengingat Harian",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "Ingatkan saya jam 20:00 jika belum catat transaksi hari ini",
                      ),
                      value: userController.isNotificationEnabled,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (bool value) {
                        userController.toggleNotification(value);
                      },
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
              backgroundColor: Theme.of(context).colorScheme.primary,
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
            child: const Text("Simpan", ),
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      controller.setPayday(selectedDay);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: currentPayday - 1,
                  ),
                  onSelectedItemChanged: (int index) {
                    selectedDay = index + 1;
                  },
                  children: List<Widget>.generate(31, (int index) {
                    return Center(
                      child: Text(
                        'Tanggal ${index + 1}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildColorOption(BuildContext context, UserController userController, int colorHex, String label) {
    final isSelected = userController.themeColor == colorHex;
    final color = Color(colorHex);

    return GestureDetector(
      onTap: () {
        userController.setThemeColor(colorHex);
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
