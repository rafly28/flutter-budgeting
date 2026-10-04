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
import 'add_expense_page.dart';
import '../controllers/user_controller.dart';

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
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 50,
                                  bottom: -40,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userController.isBalanceHidden
                                                ? 'Rp ••••••'
                                                : CurrencyInputFormatter.format(
                                                    account.balance,
                                                  ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          if (account.assetType != 'cash' &&
                                              account.avgBuyPrice > 0)
                                            Builder(
                                              builder: (ctx) {
                                                final totalCost =
                                                    account.unitCount *
                                                    account.avgBuyPrice;
                                                final currentVal =
                                                    account.balance;
                                                final pl = totalCost > 0
                                                    ? ((currentVal -
                                                              totalCost) /
                                                          totalCost *
                                                          100)
                                                    : 0.0;
                                                final isProfit = pl >= 0;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isProfit
                                                          ? Colors.greenAccent
                                                                .withOpacity(
                                                                  0.2,
                                                                )
                                                          : Colors.redAccent
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${isProfit ? '+' : ''}${userController.isBalanceHidden ? '••' : pl.toStringAsFixed(2)}%',
                                                      style: TextStyle(
                                                        color: isProfit
                                                            ? Colors.greenAccent
                                                            : Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
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
                                                account
                                                        .accountHolderName
                                                        .isEmpty
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
                                                userController.isBalanceHidden
                                                    ? '••••••••'
                                                    : (account
                                                              .accountNumber
                                                              .isEmpty
                                                          ? '**** **** ****'
                                                          : account
                                                                .accountNumber),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  letterSpacing: 2,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Tombol Aksi Cepat (Nabung & Copy)
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AddExpensePage(
                                                            savingDestination:
                                                                account.name,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    "Nabung",
                                                    style: TextStyle(
                                                      color: _getCardColors(
                                                        index,
                                                      )[0],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () {
                                                  if (account
                                                      .accountNumber
                                                      .isNotEmpty) {
                                                    String copyText = "";
                                                    if (account
                                                        .bankName
                                                        .isNotEmpty) {
                                                      copyText +=
                                                          "Bank: ${account.bankName}\n";
                                                    }
                                                    copyText +=
                                                        "No. Rekening: ${account.accountNumber}\n";
                                                    if (account
                                                        .accountHolderName
                                                        .isNotEmpty) {
                                                      copyText +=
                                                          "Atas Nama: ${account.accountHolderName}";
                                                    }

                                                    Clipboard.setData(
                                                      ClipboardData(
                                                        text: copyText.trim(),
                                                      ),
                                                    );
                                                    toastification.show(
                                                      context: context,
                                                      title: const Text(
                                                        'Info Rekening Disalin',
                                                      ),
                                                      type: ToastificationType
                                                          .success,
                                                      style: ToastificationStyle
                                                          .flat,
                                                      autoCloseDuration:
                                                          const Duration(
                                                            seconds: 3,
                                                          ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                      decoration: const InputDecoration(
                        labelText:
                            'Simbol / Ticker (Cth: XAU, bitcoin, BBCA.JK)',
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
                onPressed: () {
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

                    double calcBalance = assetType == 'cash'
                        ? finalBalance
                        : (unitCount * avgBuyPrice);
                    if (isEdit &&
                        assetType != 'cash' &&
                        accountToEdit.lastMarketPrice > 0) {
                      calcBalance = unitCount * accountToEdit.lastMarketPrice;
                    }

                    if (isEdit) {
                      controller.updateSavingDetails(
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
                      );
                    } else {
                      controller.addSavingAccount(
                        nameCtrl.text,
                        calcBalance,
                        assetType == 'cash' ? bankCtrl.text : '',
                        assetType == 'cash' ? accNumCtrl.text : '',
                        assetType == 'cash' ? holderCtrl.text : '',
                        assetType: assetType,
                        unitCount: unitCount,
                        avgBuyPrice: avgBuyPrice,
                        symbol: symbolCtrl.text.trim(),
                      );
                    }
                    Navigator.pop(context);
                    controller.refreshMarketPrices();
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
