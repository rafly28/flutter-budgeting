import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // 👈 Menggunakan package kalender Anda

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';
import 'add_expense_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat =
      CalendarFormat.week; // Default tampil per minggu agar hemat tempat

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final now = DateTime.now();

    // 🎯 BATAS KALENDER: Maksimal 1 bulan ke belakang, dan maksimal hari ini
    final firstDate = DateTime(now.year, now.month - 1, now.day);
    final lastDate = now;

    // Filter transaksi HANYA untuk hari yang dipilih di kalender
    final filteredExpenses = expenseController.expenses.where((e) {
      return isSameDay(e.date, _selectedDay);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          // 🔹 KALENDER INTERAKTIF
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: firstDate,
              lastDay: lastDate,
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // update bulan yang sedang dilihat
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // 🔹 DAFTAR TRANSAKSI PADA TANGGAL TERSEBUT
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tidak ada transaksi pada\n${DateFormat('d MMM y', 'id_ID').format(_selectedDay)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = filteredExpenses.reversed
                          .toList()[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: exp.type == "income"
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              exp.type == "income"
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: exp.type == "income"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(
                            exp.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: exp.note?.isNotEmpty == true
                              ? Text(exp.note!)
                              : null,
                          trailing: Text(
                            CurrencyInputFormatter.format(exp.amount),
                            style: TextStyle(
                              color: exp.type == "income"
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 TOMBOL ADD (Otomatis menggunakan tanggal yang dipilih)
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Transaksi Susulan',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpensePage(
                fixedDate: _selectedDay, // 👈 Kirim tanggal kalender ke Form
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
