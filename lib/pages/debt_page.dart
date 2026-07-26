import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/debt_controller.dart';
import '../models/debt.dart';
import '../utils/currency_input_formatter.dart';
import 'add_debt_page.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Hutang & Piutang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDebtPage()),
            );
          },
          backgroundColor: Colors.blue.shade700,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Catat Baru", style: TextStyle(color: Colors.white)),
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
    final debts = type == 'piutang' ? debtController.activePiutang : debtController.activeHutang;

    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              type == 'piutang' ? "Belum ada piutang berjalan" : "Belum ada hutang berjalan",
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
        final progress = debt.amount > 0 ? (debt.paidAmount / debt.amount) : 0.0;
        final isCompleted = debt.paidAmount >= debt.amount;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                          backgroundColor: type == 'piutang' ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            Icons.person,
                            color: type == 'piutang' ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.personName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(debt.createdAt),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : Colors.blue.shade700,
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
                    color: isCompleted ? Colors.green : Colors.blue.shade700,
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
                      label: Text(type == 'piutang' ? "Terima Pembayaran" : "Bayar Cicilan"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: type == 'piutang' ? Colors.green.shade700 : Colors.red.shade700,
                        side: BorderSide(color: type == 'piutang' ? Colors.green.shade700 : Colors.red.shade700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showDeleteConfirm(BuildContext context, DebtController ctrl, Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Catatan?"),
        content: const Text("Catatan ini akan dihapus permanen. Transaksi di history tidak akan terhapus."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ctrl.deleteDebt(debt);
              Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPayDialog(BuildContext context, DebtController ctrl, Debt debt) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(debt.type == 'piutang' ? "Terima Pembayaran" : "Bayar Cicilan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sisa: ${CurrencyInputFormatter.format(debt.amount - debt.paidAmount)}", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                labelText: "Nominal",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () {
              final cleanAmt = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
              final amt = double.tryParse(cleanAmt) ?? 0.0;
              if (amt > 0) {
                ctrl.payDebt(debt, amt);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
