import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expenseController = context.watch<ExpenseController>();
    final expenses = expenseController.expenses;

    // 🔹 Boleh mundur hingga 1 bulan ke belakang untuk debug
    final firstDay = DateTime(
      DateTime.now().year,
      DateTime.now().month - 1,
      1,
    );

    // 🔹 Filter transaksi sesuai tanggal yang dipilih
    final filteredExpenses = expenses.where((e) =>
        e.date.year == _selectedDay.year &&
        e.date.month == _selectedDay.month &&
        e.date.day == _selectedDay.day).toList();

    // 🔹 Hitung total pengeluaran & pemasukan
    final totalPengeluaran = filteredExpenses
        .where((e) => e.type == "expense")
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalPemasukan = filteredExpenses
        .where((e) => e.type == "income")
        .fold<double>(0.0, (sum, e) => sum + e.amount);

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
            // 🔹 Tampilkan titik pada hari yang punya transaksi
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
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Total Pemasukan: ${CurrencyInputFormatter.format(totalPemasukan)}",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
          ),
          Text(
            "Total Pengeluaran: ${CurrencyInputFormatter.format(totalPengeluaran)}",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(child: Text("Tidak ada transaksi di tanggal ini"))
                : ListView.builder(
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final Expense exp = filteredExpenses[index];
                      
                      // 💡 FITUR BARU: Menggunakan Dismissible untuk Swiping-to-Delete
                      return Dismissible(
                        // PENTING: ValueKey(exp) hanya berfungsi jika Expense memiliki hashCode yang stabil.
                        // Lebih baik menggunakan ID unik (exp.id) dari model.
                        key: ValueKey(exp), 
                        
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                        ),
                        
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Konfirmasi Hapus"),
                                content: Text(
                                  "Apakah Anda yakin ingin menghapus transaksi ${exp.type == 'income' ? 'Pemasukan' : 'Pengeluaran'} senilai ${CurrencyInputFormatter.format(exp.amount)}?",
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    // Jika menekan BATAL, pop(false) -> item kembali ke posisi semula
                                    onPressed: () => Navigator.of(context).pop(false), 
                                    child: const Text("BATAL"),
                                  ),
                                  TextButton(
                                    // Jika menekan HAPUS, pop(true) -> onDismissed akan dieksekusi
                                    onPressed: () => Navigator.of(context).pop(true), 
                                    child: const Text("HAPUS", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        
                        onDismissed: (_) {
                          // 💡 ACTION: Panggil fungsi delete, hanya berjalan jika confirmDismiss mengembalikan true
                          context.read<ExpenseController>().removeExpense(
                            expenseController.expenses.indexOf(exp),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${exp.type == 'income' ? 'Pemasukan' : 'Pengeluaran'} (${CurrencyInputFormatter.format(exp.amount)}) dihapus"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        
                        // 💡 CHILD: Card adalah konten yang akan di-swipe
                        child: Card( 
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            // 💡 LOGIKA IKON: Pemasukan (Hijau, Panah Atas), Pengeluaran (Merah, Panah Bawah)
                            leading: Icon(
                              exp.type == "income"
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: exp.type == "income" ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            
                            // 💡 TITLE: Sekarang menampilkan Jumlah (lebih penting)
                            title: Text(
                              CurrencyInputFormatter.format(exp.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: exp.type == "income" ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            
                            // 💡 SUBTITLE: Sekarang menampilkan Catatan atau Kategori
                            subtitle: Text(
                              exp.note?.isNotEmpty == true
                                  ? exp.note!
                                  : exp.category,
                            ),
                            
                            // 💡 TRAILING: Tampilkan kategori
                            trailing: Text(
                              exp.category,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpensePage(initialDate: _selectedDay),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
    );
  }
}