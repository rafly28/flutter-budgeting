import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseController>().expenses;

    // tentukan firstDay sesuai transaksi pertama
    DateTime firstDay;
    if (expenses.isNotEmpty) {
      expenses.sort((a, b) => a.date.compareTo(b.date));
      firstDay = expenses.first.date;
    } else {
      firstDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
    }

    // filter transaksi sesuai tanggal yang dipilih
    final filteredExpenses = expenses.where((e) =>
        e.date.year == _selectedDay.year &&
        e.date.month == _selectedDay.month &&
        e.date.day == _selectedDay.day).toList();
        // e.type == "expense").toList();

    final totalPengeluaran = filteredExpenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Histori Transaksi")),
      body: Column(
        children: [
          TableCalendar<Expense>(
            focusedDay: _focusedDay,
            firstDay: firstDay,
            lastDay: DateTime.now(),
            locale: 'id_ID',
            calendarFormat: CalendarFormat.month,

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },

            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),

            // 🔹 Tampilkan event marker
            eventLoader: (day) {
              return expenses.where((e) =>
                  e.date.year == day.year &&
                  e.date.month == day.month &&
                  e.date.day == day.day).toList();
            },

            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          Text(
            "Total Pengeluaran: ${CurrencyInputFormatter.format(totalPengeluaran)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(child: Text("Tidak ada pengeluaran di tanggal ini"))
                : ListView.builder(
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = filteredExpenses[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.money),
                          title: Text(CurrencyInputFormatter.format(exp.amount)),
                          subtitle: Text(
                            exp.note?.isNotEmpty == true
                                ? exp.note!
                                : exp.category,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
