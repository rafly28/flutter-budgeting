import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy to Clipboard
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/saving_controller.dart';
import '../controllers/expense_controller.dart';
import '../models/saving_account.dart';
import '../utils/currency_input_formatter.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  int _currentCardIndex = 0; // Melacak kartu mana yang sedang dilihat

  @override
  Widget build(BuildContext context) {
    final savingController = context.watch<SavingController>();
    final expenseController = context
        .watch<ExpenseController>(); // Untuk ambil riwayat transaksi
    final savings = savingController.savings;
    final totalBalance = savingController.totalSavingsBalance;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Kelola Tabungan'), elevation: 0),
      body: Column(
        children: [
          // 🔹 BAGIAN 1: TOTAL KEKAYAAN TABUNGAN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            color: Colors.blue.shade700,
            child: Column(
              children: [
                const Text(
                  'Total Saldo Tabungan',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
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

          const SizedBox(height: 20),

          // 🔹 BAGIAN 2: KARTU ATM SWIPE-ABLE
          if (savings.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Belum ada tabungan.\nKlik tombol + di bawah.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: savings.length,
                onPageChanged: (index) {
                  setState(() => _currentCardIndex = index);
                },
                itemBuilder: (context, index) {
                  final account = savings[index];
                  // Ubah ukuran kartu agar yang di tengah lebih besar
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: _currentCardIndex == index ? 0 : 15,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: _getCardColors(
                          index,
                        ), // Warna dinamis berdasarkan index
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                account.bankName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyInputFormatter.format(account.balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.accountHolderName.isEmpty
                                        ? 'Atas Nama'
                                        : account.accountHolderName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    account.accountNumber.isEmpty
                                        ? '**** **** ****'
                                        : account.accountNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              // 📋 Tombol Copy!
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (account.accountNumber.isNotEmpty) {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: account.accountNumber,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Nomor Rekening Disalin!',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik-Titik di bawah kartu
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                savings.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentCardIndex == index
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 BAGIAN 3: DAFTAR TRANSAKSI KHUSUS KARTU INI
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Riwayat Kartu Ini",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddOrEditDialog(
                            context,
                            savingController,
                            savings[_currentCardIndex],
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _buildTransactionList(
                        expenseController,
                        savings[_currentCardIndex].name,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(context, savingController, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Fungsi untuk memfilter transaksi yang SUMBER DANA-nya adalah kartu yang sedang dilihat
  Widget _buildTransactionList(
    ExpenseController controller,
    String accountName,
  ) {
    final accountExpenses = controller.expenses
        .where((e) => e.source == accountName)
        .toList();

    if (accountExpenses.isEmpty)
      return const Center(child: Text("Belum ada transaksi di akun ini"));

    return ListView.builder(
      itemCount: accountExpenses.length,
      itemBuilder: (context, index) {
        final exp = accountExpenses.reversed.toList()[index];
        return ListTile(
          leading: Icon(
            exp.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
            color: exp.type == "income" ? Colors.green : Colors.red,
          ),
          title: Text(exp.category),
          subtitle: Text(exp.note ?? ""),
          trailing: Text(
            CurrencyInputFormatter.format(exp.amount),
            style: TextStyle(
              color: exp.type == "income" ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  // Memberikan warna gradien berbeda tiap index kartu
  List<Color> _getCardColors(int index) {
    final colors = [
      [Colors.blue.shade800, Colors.blue.shade400],
      [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
      [Colors.teal.shade800, Colors.teal.shade400],
      [Colors.orange.shade800, Colors.orange.shade400],
    ];
    return colors[index % colors.length];
  }

  // Dialog yang sama untuk Add atau Edit Tabungan
  void _showAddOrEditDialog(
    BuildContext context,
    SavingController controller,
    SavingAccount? accountToEdit,
  ) {
    final isEdit = accountToEdit != null;

    final nameCtrl = TextEditingController(
      text: isEdit ? accountToEdit.name : '',
    );
    final bankCtrl = TextEditingController(
      text: isEdit ? accountToEdit.bankName : '',
    );
    final accNumCtrl = TextEditingController(
      text: isEdit ? accountToEdit.accountNumber : '',
    );
    final holderCtrl = TextEditingController(
      text: isEdit ? accountToEdit.accountHolderName : '',
    );

    // Format saldo agar rapi (misal: 1.500.000)
    final initialBalance = isEdit && accountToEdit.balance > 0
        ? NumberFormat.decimalPattern(
            "id_ID",
          ).format(accountToEdit.balance.toInt())
        : '';
    final balanceCtrl = TextEditingController(text: initialBalance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Tabungan' : 'Tabungan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama (Cth: Dana Darurat)',
                ),
              ),
              TextField(
                controller: bankCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Bank / E-Wallet (Cth: BCA)',
                ),
              ),
              TextField(
                controller: accNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nomor Rekening'),
              ),
              TextField(
                controller: holderCtrl,
                decoration: const InputDecoration(labelText: 'Atas Nama'),
              ),
              // 👇 Field Saldo sekarang tampil di mode Edit maupun Add
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Saldo Tabungan (Koreksi jika salah)',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                controller.deleteSaving(accountToEdit);
                Navigator.pop(context);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                // Bersihkan titik sebelum disimpan
                final String cleanAmount = balanceCtrl.text.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                final double finalBalance = double.tryParse(cleanAmount) ?? 0.0;

                if (isEdit) {
                  controller.updateSavingDetails(
                    accountToEdit, // 👈 WAJIB PAKAI ! (Null Check)
                    nameCtrl.text,
                    bankCtrl.text,
                    accNumCtrl.text,
                    holderCtrl.text,
                    finalBalance, // 👈 Masukkan saldo baru
                  );
                } else {
                  controller.addSavingAccount(
                    nameCtrl.text,
                    finalBalance,
                    bankCtrl.text,
                    accNumCtrl.text,
                    holderCtrl.text,
                  );
                }
                Navigator.pop(context); // Tutup dialog
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
