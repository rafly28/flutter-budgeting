import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/expense_controller.dart';
import '../utils/currency_input_formatter.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Inisialisasi: Pilih bulan saat ini
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  // Fungsi utilitas untuk mendapatkan daftar 4 bulan terakhir (termasuk bulan saat ini)
  List<DateTime> _getAvailableMonths(DateTime current) {
    List<DateTime> months = [];
    // Loop 4 kali (untuk bulan 0, -1, -2, -3)
    for (int i = 0; i < 3; i++) {
      // Menggunakan constructor DateTime untuk mundur secara otomatis (misal, jika Jan - 1, maka menjadi Des tahun lalu)
      months.add(DateTime(current.year, current.month - i));
    }
    // Urutkan dari yang terbaru ke yang terlama (bulan saat ini di atas)
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExpenseController>();
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    
    final now = DateTime.now();
    final availableMonths = _getAvailableMonths(now);

    final summary = controller.getMonthlySummary(year, month);
    final expenseBreakdown =
        controller.getCategoryBreakdown(year, month, type: "expense");
    final incomeBreakdown =
        controller.getCategoryBreakdown(year, month, type: "income");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistik Bulanan"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown di dalam Card agar lebih menonjol
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: DropdownButtonFormField<DateTime>(
                  initialValue: availableMonths.contains(_selectedMonth)
                      ? _selectedMonth
                      : availableMonths.first,
                  decoration: const InputDecoration(
                    labelText: "Pilih Bulan Laporan",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  items: availableMonths.map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child:
                          Text(DateFormat('MMMM yyyy', 'id_ID').format(date)),
                    );
                  }).toList(),
                  onChanged: (DateTime? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                ),
              ),
            ),

            // 📊 Ringkasan bulanan
            const Text("Ringkasan Keuangan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      "Total Pemasukan",
                      CurrencyInputFormatter.format(summary["income"] ?? 0),
                      Colors.green,
                      Icons.arrow_upward_rounded,
                    ),
                    const Divider(height: 10),
                    _buildSummaryRow(
                      "Total Pengeluaran",
                      CurrencyInputFormatter.format(summary["expense"] ?? 0),
                      Colors.red,
                      Icons.arrow_downward_rounded,
                    ),
                    const Divider(height: 20, thickness: 2),
                    _buildSummaryRow(
                      "Saldo Akhir",
                      CurrencyInputFormatter.format(summary["balance"] ?? 0),
                      // Saldo negatif merah, Saldo positif hijau/biru
                      (summary["balance"] ?? 0) < 0 ? Colors.red.shade700 : Colors.blue.shade700,
                      (summary["balance"] ?? 0) >= 0 ? Icons.check_circle : Icons.warning_rounded,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 📈 Breakdown pengeluaran
            Text(
              "Kategori Pengeluaran (${CurrencyInputFormatter.format(summary["expense"] ?? 0)})",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildCategoryList(expenseBreakdown, summary["expense"] ?? 0, Colors.red),

            const SizedBox(height: 24),

            // 📈 Breakdown pemasukan
            Text(
              "Kategori Pemasukan (${CurrencyInputFormatter.format(summary["income"] ?? 0)})",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildCategoryList(incomeBreakdown, summary["income"] ?? 0, Colors.green),
          ],
        ),
      ),
    );
  }

  // Widget Summary Row diperbarui untuk menyertakan ikon
  Widget _buildSummaryRow(String label, String value, Color color, IconData icon,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Category List diperbarui untuk menyertakan progress bar
  Widget _buildCategoryList(
      Map<String, double> data, double total, Color color) {
    if (data.isEmpty) {
      return const Text("Tidak ada data untuk bulan ini", style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Column(
      children: data.entries.map((entry) {
        final percentage = total > 0 ? (entry.value / total) : 0.0;
        final percentageString = (percentage * 100).toStringAsFixed(1);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${CurrencyInputFormatter.format(entry.value)} ($percentageString%)",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
