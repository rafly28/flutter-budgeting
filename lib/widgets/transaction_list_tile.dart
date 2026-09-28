import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/currency_input_formatter.dart';

class TransactionListTile extends StatelessWidget {
  final Expense exp;
  final Widget leading;
  final VoidCallback? onTap;

  const TransactionListTile({
    super.key,
    required this.exp,
    required this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Judul Utama (title): Utamakan exp.note jika ada, jika kosong gunakan kategori
    final String titleText = (exp.note != null && exp.note!.trim().isNotEmpty)
        ? exp.note!.trim()
        : exp.category;

    // Sub-judul (subtitle): Format terpadu: [Kategori] - [Deskripsi Transaksi] - [Sumber Rekening]
    final String categoryPart = exp.category;
    final String notePart = (exp.note != null && exp.note!.trim().isNotEmpty)
        ? exp.note!.trim()
        : "-";
    final String sourcePart = exp.source.isNotEmpty ? exp.source : "Budget Utama";
    final String subtitleText = "$categoryPart - $notePart - $sourcePart";

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: leading,
      title: Text(
        titleText,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitleText,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(
        CurrencyInputFormatter.format(exp.amount),
        style: TextStyle(
          color: exp.type == "transfer"
              ? Colors.blue
              : (exp.type == "income" ? Colors.green : Colors.red),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
