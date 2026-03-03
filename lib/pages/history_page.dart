import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final now = DateTime.now();

    final firstDate = DateTime(now.year, now.month - 2, now.day);
    final lastDate = now;

    // Filter transaksi berdasarkan kalender
    final filteredExpenses = expenseController.expenses.where((e) {
      return isSameDay(e.date, _selectedDay);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // 👈 Sama dengan Dashboard
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔹 KALENDER (Diberi sedikit styling melengkung di bawah)
          // 🔹 KALENDER (Desain Premium)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
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
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format)
                  setState(() => _calendarFormat = format);
              },

              // 👇 1. Styling Header Kalender
              headerStyle: HeaderStyle(
                formatButtonVisible:
                    false, // Sembunyikan tombol format agar lebih bersih
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),

              // 👇 2. Styling Hari & Angka Kalender
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false, // Sembunyikan tanggal bulan lain
                // Tampilan saat hari dipilih
                selectedDecoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Bentuk kotak melengkung (Squircle)
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),

                // Tampilan untuk "Hari Ini" (Today)
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                todayTextStyle: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),

                // Tampilan hari-hari biasa
                defaultDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                weekendDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                weekendTextStyle: const TextStyle(
                  color: Colors.redAccent,
                ), // Hari libur warna merah
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 🔹 DAFTAR TRANSAKSI
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = filteredExpenses.reversed
                          .toList()[index];

                      return Dismissible(
                        key: ValueKey(exp.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) {
                          expenseController.removeExpense(
                            expenseController.expenses.indexOf(exp),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("🗑️ Transaksi dihapus"),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: exp.type == "transfer"
                                  ? Colors.blue.shade50
                                  : (exp.type == "income"
                                        ? Colors.green.shade50
                                        : Colors.red.shade50),
                              child: Icon(
                                exp.type == "transfer"
                                    ? Icons.sync_alt
                                    : (exp.type == "income"
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward),
                                color: exp.type == "transfer"
                                    ? Colors.blue
                                    : (exp.type == "income"
                                          ? Colors.green
                                          : Colors.red),
                              ),
                            ),
                            title: Text(
                              exp.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              exp.note?.isNotEmpty == true
                                  ? exp.note!
                                  : exp.source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              CurrencyInputFormatter.format(exp.amount),
                              style: TextStyle(
                                color: exp.type == "transfer"
                                    ? Colors.blue
                                    : (exp.type == "income"
                                          ? Colors.green
                                          : Colors.red),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            // 👇 FITUR EDIT SAAT DI-KLIK
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpensePage(expenseToEdit: exp),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 TOMBOL ADD (Otomatis menggunakan tanggal yang dipilih)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Catat Susulan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpensePage(fixedDate: _selectedDay),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // 👈 Di tengah bawah agar konsisten
    );
  }
}
