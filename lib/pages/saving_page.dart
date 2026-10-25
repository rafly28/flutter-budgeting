import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:toastification/toastification.dart';

import '../controllers/saving_controller.dart';
import '../controllers/expense_controller.dart';
import '../models/saving_account.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/transaction_list_tile.dart';
import '../widgets/saving_card.dart';
import 'add_expense_page.dart';
import '../controllers/user_controller.dart';

/// Pemecahan "Tunai / Investasi" di bawah total tabungan.
class _TotalPart extends StatelessWidget {
  final String label;
  final double amount;
  final bool hidden;

  const _TotalPart({
    required this.label,
    required this.amount,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(color: foreground.withOpacity(0.7), fontSize: 11),
        ),
        Text(
          hidden ? '••••••' : CurrencyInputFormatter.format(amount),
          style: TextStyle(
            color: foreground.withOpacity(0.95),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SavingController>().refreshMarketPrices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savingController = context.watch<SavingController>();
    final expenseController = context.watch<ExpenseController>();
    final userController = context.watch<UserController>();
    final savings = savingController.savings;
    if (_currentCardIndex >= savings.length && savings.isNotEmpty) {
      _currentCardIndex = savings.length - 1;
    } else if (savings.isEmpty) {
      _currentCardIndex = 0;
    }
    final totalBalance = savingController.totalSavingsBalance;
    final cashPart = savingController.cashBalance;
    final investmentPart = savingController.investmentBalance;

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Tema Dashboard
      appBar: AppBar(
        title: const Text(
          'Kelola Tabungan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<SavingController>().refreshMarketPrices(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                children: [
                  // 🔹 BAGIAN 1: TOTAL KEKAYAAN TABUNGAN (Melengkung)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 30, top: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Saldo Tabungan',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: userController.toggleBalanceVisibility,
                              child: Icon(
                                userController.isBalanceHidden
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          userController.isBalanceHidden
                              ? 'Rp ••••••'
                              : CurrencyInputFormatter.format(totalBalance),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        // Pemecahan kas vs investasi supaya pergerakan harga
                        // aset tidak terlihat seperti saldo yang berubah
                        // sendiri.
                        if (cashPart > 0 || investmentPart > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (cashPart > 0)
                                  _TotalPart(
                                    label: 'Tunai',
                                    amount: cashPart,
                                    hidden: userController.isBalanceHidden,
                                  ),
                                if (cashPart > 0 && investmentPart > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                if (investmentPart > 0)
                                  _TotalPart(
                                    label: 'Investasi',
                                    amount: investmentPart,
                                    hidden: userController.isBalanceHidden,
                                  ),
                              ],
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 224,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.88),
                        itemCount: savings.length,
                        onPageChanged: (index) =>
                            setState(() => _currentCardIndex = index),
                        itemBuilder: (context, index) {
                          final account = savings[index];
                          final isActive = _currentCardIndex == index;
                          return SavingCard(
                            account: account,
                            isActive: isActive,
                            isBalanceHidden: userController.isBalanceHidden,
                            onAddFunds: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddExpensePage(
                                    savingDestination: account.name,
                                  ),
                                ),
                              );
                            },
                            onCopyAccount: () => _copyAccount(context, account),
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
                                ? Theme.of(context).colorScheme.primary
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
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text(
          "Dompet Baru",
          style: TextStyle(fontWeight: FontWeight.bold),
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
      if (e.source == accountName) {
        return true; // Jika kartu ini sebagai pengirim
      }

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

        return TransactionListTile(
          exp: exp,
          showDate: true,
          isIncoming: isIncomeForThisCard,
        );
      },
    );
  }

  Future<void> _copyAccount(BuildContext context, SavingAccount account) async {
    if (account.accountNumber.isEmpty) return;
    final buffer = StringBuffer();
    if (account.bankName.isNotEmpty) {
      buffer.writeln('Bank: ${account.bankName}');
    }
    buffer.writeln('No. Rekening: ${account.accountNumber}');
    if (account.accountHolderName.isNotEmpty) {
      buffer.write('Atas Nama: ${account.accountHolderName}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (!context.mounted) return;
    toastification.show(
      context: context,
      title: const Text('Info Rekening Disalin'),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
    );
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

    String assetType = isEdit ? accountToEdit.assetType : 'cash';
    final symbolCtrl = TextEditingController(
      text: isEdit ? accountToEdit.symbol : '',
    );
    final unitCountCtrl = TextEditingController(
      text: isEdit && accountToEdit.unitCount > 0
          ? accountToEdit.unitCount.toString()
          : '',
    );
    final avgBuyPriceCtrl = TextEditingController(
      text: isEdit && accountToEdit.avgBuyPrice > 0
          ? NumberFormat.decimalPattern(
              "id_ID",
            ).format(accountToEdit.avgBuyPrice.toInt())
          : '',
    );
    final unitLabelCtrl = TextEditingController(
      text: isEdit ? accountToEdit.unitLabel : '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEdit ? 'Edit Tabungan/Aset' : 'Tabungan/Aset Baru',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: assetType,
                    decoration: const InputDecoration(labelText: 'Tipe Aset'),
                    items: const [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('Uang Tunai'),
                      ),
                      DropdownMenuItem(value: 'gold', child: Text('Emas')),
                      DropdownMenuItem(value: 'crypto', child: Text('Kripto')),
                      DropdownMenuItem(value: 'stock', child: Text('Saham')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        assetType = val ?? 'cash';
                      });
                    },
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama (Cth: Dana Darurat)',
                    ),
                  ),
                  if (assetType == 'cash') ...[
                    TextField(
                      controller: bankCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Bank / E-Wallet (Cth: BCA)',
                      ),
                    ),
                    TextField(
                      controller: accNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Rekening',
                      ),
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
                  ] else ...[
                    TextField(
                      controller: symbolCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Simbol / Ticker (Cth: XAU, bitcoin, BBCA.JK)',
                        helperText: assetType == 'gold'
                            ? 'Opsional untuk emas — harga Antam diambil otomatis.'
                            : 'Wajib untuk kripto dan saham.',
                        helperMaxLines: 2,
                      ),
                    ),
                    TextField(
                      controller: unitCountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Unit (Cth: 5.5 Gram / Lot / Coin)',
                      ),
                    ),
                    TextField(
                      controller: unitLabelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Satuan (Cth: gram, lot, koin)',
                        helperText: 'Kosongkan untuk memakai satuan default.',
                      ),
                    ),
                    TextField(
                      controller: avgBuyPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Harga Modal Rata-rata per Unit',
                        prefixText: 'Rp ',
                      ),
                    ),
                  ],
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
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    final String cleanAmount = balanceCtrl.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final double finalBalance =
                        double.tryParse(cleanAmount) ?? 0.0;

                    final String cleanAvg = avgBuyPriceCtrl.text.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    final double avgBuyPrice = double.tryParse(cleanAvg) ?? 0.0;
                    final double unitCount =
                        double.tryParse(
                          unitCountCtrl.text.replaceAll(',', '.'),
                        ) ??
                        0.0;

                    double calcBalance;
                    if (assetType == 'cash') {
                      calcBalance = finalBalance;
                    } else {
                      final derived = unitCount * avgBuyPrice;
                      // Mengubah akun tunai jadi aset tanpa mengisi unit atau
                      // modal akan menurunkan saldo jadi 0. Kalau saldo
                      // sebelumnya sudah ada, pertahankan sebagai modal yang
                      // diinvestasikan.
                      final previousBalance = isEdit
                          ? accountToEdit.balance
                          : 0.0;
                      calcBalance = derived > 0 || previousBalance <= 0
                          ? derived
                          : previousBalance;
                    }

                    if (isEdit) {
                      final saved = await controller.updateSavingDetails(
                        accountToEdit,
                        nameCtrl.text,
                        assetType == 'cash' ? bankCtrl.text : '',
                        assetType == 'cash' ? accNumCtrl.text : '',
                        assetType == 'cash' ? holderCtrl.text : '',
                        calcBalance,
                        assetType: assetType,
                        unitCount: unitCount,
                        avgBuyPrice: avgBuyPrice,
                        symbol: symbolCtrl.text.trim(),
                        unitLabel: unitLabelCtrl.text.trim(),
                      );
                      if (!saved) {
                        if (context.mounted) {
                          _showError(
                            context,
                            'Gagal menyimpan. Nama sudah dipakai.',
                          );
                        }
                        return;
                      }
                    } else {
                      final added = await controller.addSavingAccount(
                        nameCtrl.text,
                        calcBalance,
                        assetType == 'cash' ? bankCtrl.text : '',
                        assetType == 'cash' ? accNumCtrl.text : '',
                        assetType == 'cash' ? holderCtrl.text : '',
                        assetType: assetType,
                        unitCount: unitCount,
                        avgBuyPrice: avgBuyPrice,
                        symbol: symbolCtrl.text.trim(),
                        unitLabel: unitLabelCtrl.text.trim(),
                      );
                      if (!added) {
                        if (context.mounted) {
                          _showError(
                            context,
                            'Gagal menyimpan. Nama sudah dipakai.',
                          );
                        }
                        return;
                      }
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await controller.refreshMarketPrices();
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Menampilkan pesan error singkat ke pengguna.
void _showError(BuildContext context, String message) {
  toastification.show(
    context: context,
    title: Text(message),
    type: ToastificationType.error,
    style: ToastificationStyle.flat,
    autoCloseDuration: const Duration(seconds: 3),
  );
}
