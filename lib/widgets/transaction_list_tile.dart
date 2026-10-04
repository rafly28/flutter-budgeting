import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../controllers/category_controller.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';
import '../pages/add_expense_page.dart';

class TransactionListTile extends StatelessWidget {
  final Expense exp;
  final bool showDate;
  final bool? isIncoming;
  final bool compact;

  const TransactionListTile({
    super.key,
    required this.exp,
    this.showDate = false,
    this.isIncoming,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ListTile(
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: compact ? 20 : 25,
        backgroundColor: exp.type == "transfer"
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : (exp.type == "income"
                ? Colors.green.shade50
                : Colors.red.shade50),
        child: Builder(
          builder: (context) {
            final catCtrl = context.read<CategoryController>();
            final catList = exp.type == 'income'
                ? catCtrl.incomeCategories
                : catCtrl.expenseCategories;
            final category =
                catList.where((c) => c.name == exp.category).firstOrNull;

            if (exp.type != 'transfer' && category?.iconCodePoint != null) {
              return Icon(
                IconData(category!.iconCodePoint!,
                    fontFamily: category.iconFontFamily),
                color: exp.type == "income" ? Colors.green : Colors.red,
                size: compact ? 20 : 24,
              );
            }

            return Icon(
              exp.type == "transfer"
                  ? Icons.sync_alt
                  : (exp.type == "income"
                      ? Icons.arrow_downward
                      : Icons.arrow_upward),
              color: exp.type == "transfer"
                  ? Theme.of(context).colorScheme.primary
                  : (exp.type == "income" ? Colors.green : Colors.red),
              size: compact ? 20 : 24,
            );
          },
        ),
      ),
      title: Text(
        (exp.note != null && exp.note!.isNotEmpty)
            ? exp.note!
            : exp.category,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: compact ? 14 : 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: exp.type == 'transfer'
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : (exp.type == 'income'
                        ? Colors.green.shade50
                        : Colors.orange.shade50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exp.category,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: exp.type == 'transfer'
                      ? Theme.of(context).colorScheme.primary
                      : (exp.type == 'income'
                          ? Colors.green.shade700
                          : Colors.orange.shade700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${exp.source}${showDate ? ' • ${DateFormat('d MMM y', 'id_ID').format(exp.date)}' : ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: compact ? 11 : 12),
              ),
            ),
          ],
        ),
      ),
      trailing: Text(
        CurrencyInputFormatter.format(exp.amount),
        style: TextStyle(
          color: isIncoming != null
              ? (isIncoming! ? Colors.green : Colors.red)
              : (exp.type == "transfer"
                  ? Theme.of(context).colorScheme.primary
                  : (exp.type == "income" ? Colors.green : Colors.red)),
          fontWeight: FontWeight.bold,
          fontSize: compact ? 14 : 15,
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpensePage(expenseToEdit: exp),
          ),
        );
      },
    );

    if (compact) return content;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: content,
    );
  }
}
