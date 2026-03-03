import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _currentCardIndex = 0;

  @override
  Widget build(BuildContext context) {
    final savingController = context.watch<SavingController>();
    final expenseController = context.watch<ExpenseController>();
    final savings = savingController.savings;
    final totalBalance = savingController.totalSavingsBalance;

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Tema Dashboard
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Kelola Tabungan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔹 BAGIAN 1: TOTAL KEKAYAAN TABUNGAN (Melengkung)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Total Saldo Tabungan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  CurrencyInputFormatter.format(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 🔹 BAGIAN 2: KARTU ATM SWIPE-ABLE
          if (savings.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 70,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Belum ada tabungan.\nKlik tombol + di bawah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 210, // Sedikit diperbesar agar proporsional
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.88),
                itemCount: savings.length,
                onPageChanged: (index) =>
                    setState(() => _currentCardIndex = index),
                itemBuilder: (context, index) {
                  final account = savings[index];
                  bool isActive = _currentCardIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: isActive ? 0 : 15,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        25,
                      ), // Sudut lebih halus
                      gradient: LinearGradient(
                        colors: _getCardColors(index),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: _getCardColors(
                                  index,
                                )[0].withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        // Hiasan Glassmorphism
                        Positioned(
                          right: -20,
                          top: -20,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Positioned(
                          right: 50,
                          bottom: -40,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    account.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    account.bankName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyInputFormatter.format(account.balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.accountHolderName.isEmpty
                                            ? 'Atas Nama'
                                            : account.accountHolderName
                                                  .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        account.accountNumber.isEmpty
                                            ? '**** **** ****'
                                            : account.accountNumber,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Tombol Copy
                                  GestureDetector(
                                    onTap: () {
                                      if (account.accountNumber.isNotEmpty) {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: account.accountNumber,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Nomor Rekening Disalin!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.copy,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // Indikator Titik
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                savings.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentCardIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentCardIndex == index
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 BAGIAN 3: DAFTAR TRANSAKSI
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
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
                          icon: Icon(
                            Icons.edit_note,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                          onPressed: () => _showAddOrEditDialog(
                            context,
                            savingController,
                            savings[_currentCardIndex],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Dompet Baru",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddOrEditDialog(context, savingController, null),
      ),
    );
  }

  Widget _buildTransactionList(
    ExpenseController controller,
    String accountName,
  ) {
    // 1. Filter transaksi khusus untuk kartu ini (Sebagai pengirim ATAU penerima)
    final accountExpenses = controller.expenses.where((e) {
      if (e.source == accountName)
        return true; // Jika kartu ini sebagai pengirim

      // Jika transfer, cek apakah kartu ini adalah penerimanya (dari catatan)
      if (e.type == 'transfer' &&
          e.note != null &&
          e.note!.startsWith("Dari ")) {
        final firstDot = e.note!.indexOf(".");
        if (firstDot != -1) {
          final parts = e.note!.substring(0, firstDot).split(" ke ");
          if (parts.length > 1 && parts[1] == accountName) return true;
        }
      }
      return false;
    }).toList();

    if (accountExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text(
              "Belum ada riwayat",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accountExpenses.length,
      itemBuilder: (context, index) {
        final exp = accountExpenses.reversed.toList()[index];

        // 2. Tentukan apakah transaksi ini menambah (+) atau mengurangi (-) saldo kartu INI
        bool isIncomeForThisCard = exp.type == 'income';

        if (exp.type == 'transfer' &&
            exp.note != null &&
            exp.note!.startsWith("Dari ")) {
          final firstDot = exp.note!.indexOf(".");
          if (firstDot != -1) {
            final parts = exp.note!.substring(0, firstDot).split(" ke ");
            if (parts.length > 1 && parts[1] == accountName) {
              isIncomeForThisCard =
                  true; // Kartu ini adalah penerima transfer, jadi uang masuk (+)
            }
          }
        }

        return Card(
          elevation: 0,
          color: Colors.grey.shade50,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: isIncomeForThisCard
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Icon(
                isIncomeForThisCard
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIncomeForThisCard ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              exp.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              DateFormat('d MMM y', 'id_ID').format(exp.date),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              CurrencyInputFormatter.format(exp.amount),
              style: TextStyle(
                color: isIncomeForThisCard ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getCardColors(int index) {
    final colors = [
      [Colors.blue.shade900, Colors.blue.shade500],
      [Colors.deepPurple.shade900, Colors.deepPurple.shade400],
      [Colors.teal.shade900, Colors.teal.shade500],
      [Colors.orange.shade900, Colors.orange.shade500],
      [Colors.black87, Colors.grey.shade700], // Kartu Hitam Elegan
    ];
    return colors[index % colors.length];
  }

  // Fungsi ShowDialog tetap sama seperti milik Anda sebelumnya, tidak perlu diubah logikanya
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

    final initialBalance = isEdit && accountToEdit.balance > 0
        ? NumberFormat.decimalPattern(
            "id_ID",
          ).format(accountToEdit.balance.toInt())
        : '';
    final balanceCtrl = TextEditingController(text: initialBalance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEdit ? 'Edit Tabungan' : 'Tabungan Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  labelText: 'Bank / E-Wallet (Cth: BCA)',
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
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Saldo Tabungan',
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
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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
                final String cleanAmount = balanceCtrl.text.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                final double finalBalance = double.tryParse(cleanAmount) ?? 0.0;

                if (isEdit) {
                  controller.updateSavingDetails(
                    accountToEdit,
                    nameCtrl.text,
                    bankCtrl.text,
                    accNumCtrl.text,
                    holderCtrl.text,
                    finalBalance,
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
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
