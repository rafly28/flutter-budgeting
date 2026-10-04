import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../controllers/debt_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/saving_controller.dart';
import '../models/debt.dart';
import '../utils/currency_input_formatter.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            "Hutang & Piutang",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Piutang (Orang Pinjam)"),
              Tab(text: "Hutang (Saya Pinjam)"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DebtList(type: 'piutang'),
            _DebtList(type: 'hutang'),
          ],
        ),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final String type;
  const _DebtList({required this.type});

  @override
  Widget build(BuildContext context) {
    final debtController = context.watch<DebtController>();
    final debts = type == 'piutang'
        ? debtController.piutang
        : debtController.hutang;

    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              type == 'piutang'
                  ? "Belum ada catatan piutang"
                  : "Belum ada catatan hutang",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        final progress = debt.amount > 0
            ? (debt.paidAmount / debt.amount).clamp(0.0, 1.0).toDouble()
            : 0.0;
        final isCompleted = debt.isSettled || debt.paidAmount >= debt.amount;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: type == 'piutang'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            Icons.person,
                            color: type == 'piutang'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.personName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(debt.createdAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Lunas',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        _showDeleteConfirm(context, debtController, debt);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: ${CurrencyInputFormatter.format(debt.amount)}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Dibayar: ${CurrencyInputFormatter.format(debt.paidAmount)}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const Divider(height: 30),
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showPayDialog(context, debtController, debt);
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(
                        type == 'piutang'
                            ? "Terima Pembayaran"
                            : "Bayar Cicilan",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: type == 'piutang'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        side: BorderSide(
                          color: type == 'piutang'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    DebtController ctrl,
    Debt debt,
  ) async {
    var isDeleting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text("Hapus Catatan?"),
          content: const Text(
            "Semua transaksi terkait akan dihapus dan saldo setiap akun "
            "akan dikembalikan. Penghapusan dibatalkan jika rollback tidak aman.",
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      final deleted = await ctrl.deleteDebt(debt);
                      if (!dialogContext.mounted) return;

                      if (!deleted) {
                        setDialogState(() => isDeleting = false);
                        _showToast(
                          dialogContext,
                          'Catatan tidak dapat dihapus dengan aman. Data lama '
                          'ambigu atau akun terkait tidak ditemukan.',
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);
                      if (!context.mounted) return;
                      _showToast(
                        context,
                        'Catatan dan transaksi terkait berhasil dihapus.',
                        success: true,
                      );
                    },
              child: Text(
                isDeleting ? "Menghapus..." : "Hapus"
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPayDialog(
    BuildContext context,
    DebtController ctrl,
    Debt debt,
  ) async {
    final amountController = TextEditingController();
    var selectedAccount = 'Budget Utama';
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBodyContext, setDialogState) {
          final accountOptions = [
            'Budget Utama',
            ...dialogBodyContext.watch<SavingController>().savings.map(
              (account) => account.name,
            ),
          ];
          if (!accountOptions.contains(selectedAccount)) {
            selectedAccount = 'Budget Utama';
          }

          final remaining = (debt.amount - debt.paidAmount)
              .clamp(0.0, debt.amount)
              .toDouble();
          final accountBalance = dialogBodyContext
              .watch<ExpenseController>()
              .balanceFor(selectedAccount);
          final isOutgoing = debt.type == 'hutang';
          final accountLabel = isOutgoing
              ? 'Dari (Sumber Dana)'
              : 'Ke (Tujuan Dana)';

          return AlertDialog(
            title: Text(
              debt.type == 'piutang' ? "Terima Pembayaran" : "Bayar Cicilan",
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sisa: ${CurrencyInputFormatter.format(remaining)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      labelText: "Nominal",
                      helperText:
                          'Maksimal ${CurrencyInputFormatter.format(remaining)}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    accountLabel,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedAccount),
                    initialValue: selectedAccount,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: accountOptions
                        .map(
                          (account) => DropdownMenuItem(
                            value: account,
                            child: Text(
                              account,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isSaving
                        ? null
                        : (account) {
                            if (account != null) {
                              setDialogState(() => selectedAccount = account);
                            }
                          },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo: ${CurrencyInputFormatter.format(accountBalance)}',
                    style: TextStyle(
                      color: Theme.of(dialogBodyContext).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    dialogBodyContext,
                  ).colorScheme.primary,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final cleanAmt = amountController.text.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        final amount = double.tryParse(cleanAmt) ?? 0.0;

                        if (amount <= 0) {
                          _showToast(
                            dialogContext,
                            'Nominal harus lebih dari nol.',
                          );
                          return;
                        }
                        if (amount > remaining) {
                          _showToast(
                            dialogContext,
                            'Nominal melebihi sisa. Maksimal '
                            '${CurrencyInputFormatter.format(remaining)}.',
                          );
                          return;
                        }
                        if (isOutgoing && amount > accountBalance) {
                          _showToast(
                            dialogContext,
                            'Saldo $selectedAccount tidak mencukupi.',
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final saved = await ctrl.payDebt(
                          debt,
                          amount,
                          selectedAccount,
                        );
                        if (!dialogContext.mounted) return;

                        if (!saved) {
                          setDialogState(() => isSaving = false);
                          _showToast(
                            dialogContext,
                            'Pembayaran gagal. Periksa akun, saldo, dan sisa.',
                          );
                          return;
                        }

                        Navigator.pop(dialogContext);
                        if (!context.mounted) return;
                        _showToast(
                          context,
                          debt.type == 'piutang'
                              ? 'Pembayaran berhasil diterima.'
                              : 'Cicilan berhasil dibayar.',
                          success: true,
                        );
                      },
                child: Text(
                  isSaving ? "Menyimpan..." : "Simpan"
                ),
              ),
            ],
          );
        },
      ),
    );
    amountController.dispose();
  }

  void _showToast(
    BuildContext context,
    String message, {
    bool success = false,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      type: success ? ToastificationType.success : ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
