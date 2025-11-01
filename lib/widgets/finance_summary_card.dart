import 'package:flutter/material.dart';
import '../utils/currency_input_formatter.dart';

class FinanceSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const FinanceSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Budget Bulan Ini",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyInputFormatter.format(balance),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Pemasukan"),
                    Text(CurrencyInputFormatter.format(income)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Pengeluaran"),
                    Text(CurrencyInputFormatter.format(expense)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
