import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/saving_controller.dart';
import '../models/saving_account.dart';
import '../utils/currency_input_formatter.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final savingController = context.watch<SavingController>();
    final savings = savingController.savings;
    final totalBalance = savingController.totalSavingsBalance;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tabungan')),
      body: Column(
        children: [
          // 🔹 Kartu Total Saldo Tabungan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade700,
            child: Column(
              children: [
                const Text(
                  'Total Uang di Tabungan',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyInputFormatter.format(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 Daftar Tabungan
          Expanded(
            child: savings.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada tabungan.\nKlik tombol + untuk menambah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: savings.length,
                    itemBuilder: (context, index) {
                      final account = savings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            CurrencyInputFormatter.format(account.balance),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(
                                  context,
                                  account,
                                  savingController,
                                );
                              } else if (value == 'delete') {
                                _showDeleteConfirm(
                                  context,
                                  account,
                                  savingController,
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Nama'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus Tabungan'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 Tombol Tambah Tabungan Baru
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, savingController),
        tooltip: 'Tambah Tabungan',
        child: const Icon(Icons.add),
      ),
    );
  }

  // 📝 Dialog Tambah Tabungan
  void _showAddDialog(BuildContext context, SavingController controller) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tabungan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Tabungan (Cth: BCA, Darurat)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Awal',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final initialBalance =
                  double.tryParse(balanceController.text) ?? 0.0;

              if (name.isNotEmpty) {
                controller.addSavingAccount(name, initialBalance);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 📝 Dialog Edit Nama Tabungan
  void _showEditDialog(
    BuildContext context,
    SavingAccount account,
    SavingController controller,
  ) {
    final nameController = TextEditingController(text: account.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tabungan'),
        content: TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama Tabungan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                controller.updateSavingName(account, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 🗑️ Dialog Konfirmasi Hapus
  void _showDeleteConfirm(
    BuildContext context,
    SavingAccount account,
    SavingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tabungan?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${account.name}"? (Saldo ${CurrencyInputFormatter.format(account.balance)} akan ikut terhapus dari sistem).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.deleteSaving(account);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
