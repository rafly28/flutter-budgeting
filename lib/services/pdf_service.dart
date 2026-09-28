import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class PdfService {
  static Future<void> exportAndShareMonthlyReport({
    required int month,
    required int year,
    required double totalIncome,
    required double totalExpense,
    required double finalBalance,
    required List<Expense> expenses,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

    // Sort expenses by date
    expenses.sort((a, b) => b.date.compareTo(a.date));

    // Grouping transactions by date or just a flat table
    // For simplicity, we use a flat table

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(dateStr),
            pw.SizedBox(height: 20),
            _buildSummary(totalIncome, totalExpense, finalBalance),
            pw.SizedBox(height: 20),
            pw.Text(
              "Detail Transaksi",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildTransactionTable(expenses),
          ];
        },
      ),
    );

    // Save and Share
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Laporan_Keuangan_$dateStr.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share via share_plus
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Berikut adalah Laporan Keuangan bulan $dateStr',
    );
  }

  static pw.Widget _buildHeader(String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Laporan Keuangan",
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          "Bulan: $dateStr",
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(color: PdfColors.blueGrey100),
      ],
    );
  }

  static pw.Widget _buildSummary(double income, double expense, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryBox("Pemasukan", income, PdfColors.green700),
          _buildSummaryBox("Pengeluaran", expense, PdfColors.red700),
          _buildSummaryBox("Saldo Akhir", balance, PdfColors.blue700),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryBox(String title, double amount, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          CurrencyInputFormatter.format(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return pw.Text("Tidak ada transaksi bulan ini.", style: const pw.TextStyle(color: PdfColors.grey));
    }

    final tableHeaders = ["Tanggal", "Kategori", "Tipe", "Nominal"];
    
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue100,
      ),
      headerHeight: 25,
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
      ),
      cellStyle: const pw.TextStyle(
        fontSize: 10,
      ),
      data: [
        tableHeaders,
        ...expenses.map((e) {
          return [
            DateFormat('dd MMM yyyy').format(e.date),
            e.category + (e.note != null && e.note!.isNotEmpty ? "\n(${e.note})" : ""),
            e.type == 'income' ? 'Masuk' : (e.type == 'expense' ? 'Keluar' : 'Transfer'),
            CurrencyInputFormatter.format(e.amount),
          ];
        }),
      ],
    );
  }
}
