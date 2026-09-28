import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../controllers/expense_controller.dart';
import '../controllers/plan_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/helpers.dart';
import '../controllers/category_controller.dart';
import 'edit_expense_sheet.dart';

class TodayTransactionList extends StatelessWidget {
  final List<Expense> expenses;

  const TodayTransactionList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text("Belum ada transaksi hari ini"));
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final isToday = DateHelper.isToday(exp.date);

        return Dismissible(
          key: ValueKey(exp.key),
          direction: isToday && exp.debtId == null
              ? DismissDirection.endToStart
              : DismissDirection.none,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            if (exp.debtId != null) {
              toastification.show(
                context: context,
                title: const Text(
                  "Kelola transaksi ini dari menu Hutang & Piutang.",
                ),
                type: ToastificationType.info,
                style: ToastificationStyle.flat,
                autoCloseDuration: const Duration(seconds: 3),
              );
              return false;
            }
            if (!isToday) {
              toastification.show(
                context: context,
                title: const Text("Transaksi sudah tutup buku tidak bisa dihapus"),
                type: ToastificationType.error,
                style: ToastificationStyle.flat,
                autoCloseDuration: const Duration(seconds: 3),
              );
              return false;
            }
            final removed = await context
                .read<ExpenseController>()
                .removeExpense(exp);
            if (!context.mounted) return false;
            if (removed && exp.planId != null) {
              context.read<PlanController>().unmarkPaidByPlanId(exp.planId!);
            }
            toastification.show(
              context: context,
              title: Text(
                removed
                    ? "Transaksi dihapus"
                    : "Akun transaksi tidak ditemukan. Transaksi belum dihapus.",
              ),
              type: removed
                  ? ToastificationType.success
                  : ToastificationType.error,
              style: ToastificationStyle.flat,
              autoCloseDuration: const Duration(seconds: 3),
            );
            return removed;
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Builder(
                  builder: (context) {
                    final catCtrl = context.read<CategoryController>();
                    final catList = exp.type == 'income' ? catCtrl.incomeCategories : catCtrl.expenseCategories;
                    final category = catList.where((c) => c.name == exp.category).firstOrNull;

                    if (category?.iconCodePoint != null) {
                      return Icon(
                        IconData(category!.iconCodePoint!, fontFamily: category.iconFontFamily),
                        color: exp.type == "income" ? Colors.green : Colors.red,
                      );
                    }

                    return Icon(
                      exp.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                      color: exp.type == "income" ? Colors.green : Colors.red,
                    );
                  }
                ),
              ),
              title: Text(exp.note != null && exp.note!.isNotEmpty ? exp.note! : exp.category),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: exp.type == 'transfer' ? Colors.blue.shade50 : (exp.type == 'income' ? Colors.green.shade50 : Colors.orange.shade50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exp.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: exp.type == 'transfer' ? Colors.blue.shade700 : (exp.type == 'income' ? Colors.green.shade700 : Colors.orange.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (exp.note != null && exp.note!.isNotEmpty) ? exp.note! : exp.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                CurrencyInputFormatter.format(exp.amount),
                style: TextStyle(
                  color: exp.type == "income" ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                if (exp.debtId != null) {
                  toastification.show(
                    context: context,
                    title: const Text(
                      "Kelola transaksi ini dari menu Hutang & Piutang.",
                    ),
                    type: ToastificationType.info,
                    style: ToastificationStyle.flat,
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                  return;
                }
                if (!isToday) {
                  toastification.show(
                    context: context,
                    title: const Text("❌ Transaksi sudah tutup buku tidak bisa diedit"),
                    type: ToastificationType.error,
                    style: ToastificationStyle.flat,
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => EditExpenseSheet(exp: exp),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
