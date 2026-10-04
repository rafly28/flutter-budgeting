import 'package:flutter/material.dart';
import '../utils/currency_input_formatter.dart';

class FinanceSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;
  final bool isHidden;
  final VoidCallback? onToggleVisibility;

  const FinanceSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    this.isHidden = false,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A), // Slate 900
            Theme.of(context).colorScheme.primary, // Primary
            Theme.of(context).colorScheme.primary, // Primary
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // 👇 ClipRRect memastikan lingkaran dekorasi tidak keluar dari batas kartu membulat
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 🔹 Efek Lingkaran Estetik (Sekarang akan menyatu mulus ke ujung kartu)
            Positioned(
              right: -30,
              top: -30,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -40,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),

            // 🔹 Konten Utama (Padding dipindahkan khusus untuk konten teks saja)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sisa Saldo Siklus Ini",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggleVisibility,
                        child: Icon(
                          isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isHidden ? "Rp ••••••" : CurrencyInputFormatter.format(balance),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),
                  _buildBudgetProgressBar(),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.greenAccent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pemasukan",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isHidden ? "Rp ••••••" : CurrencyInputFormatter.format(income),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pengeluaran",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isHidden ? "Rp ••••••" : CurrencyInputFormatter.format(expense),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressBar() {
    double pctRemaining = income > 0 ? ((income - expense) / income).clamp(0.0, 1.0) : 0.0;
    int pctInt = (pctRemaining * 100).toInt();
    String status = "Habis";
    Color barColor = Colors.redAccent;
    
    if (pctRemaining > 0.6) {
      status = "Sangat Terkendali";
      barColor = Colors.greenAccent;
    } else if (pctRemaining > 0.2) {
      status = "Terkendali";
      barColor = Colors.orangeAccent;
    } else if (pctRemaining > 0) {
      status = "Hampir Habis";
      barColor = Colors.redAccent;
    }

    if (income == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tersisa $pctInt% - $status",
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pctRemaining,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
