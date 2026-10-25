import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/saving_account.dart';
import '../utils/asset_palette.dart';
import '../utils/currency_input_formatter.dart';

class _EmvChip extends StatelessWidget {
  const _EmvChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 23,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: [Color(0xFFD9C48A), Color(0xFFB99B4E), Color(0xFFE8D9A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: _EmvChipPainter()),
    );
  }
}

class _EmvChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7A6633).withOpacity(0.55)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final inset = size.width * 0.18;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          size.height * 0.22,
          size.width - inset * 2,
          size.height * 0.56,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AssetBadge extends StatelessWidget {
  final String assetType;
  const _AssetBadge({required this.assetType});

  static const Map<String, String> labels = {
    'gold': 'LOGAM MULIA',
    'crypto': 'KRIPTO',
    'stock': 'SAHAM',
    'cash': 'TUNAI',
  };

  @override
  Widget build(BuildContext context) {
    final label = labels[assetType];
    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class SavingCard extends StatelessWidget {
  final SavingAccount account;
  final bool isBalanceHidden;
  final bool isActive;
  final VoidCallback onAddFunds;
  final VoidCallback onCopyAccount;

  const SavingCard({
    super.key,
    required this.account,
    required this.isBalanceHidden,
    required this.isActive,
    required this.onAddFunds,
    required this.onCopyAccount,
  });

  static bool isPriceStale(SavingAccount account) {
    final fetchedAt = account.priceFetchedAt;
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) > const Duration(hours: 6);
  }

  static String priceAgeLabel(DateTime fetchedAt) {
    final elapsed = DateTime.now().difference(fetchedAt);
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} menit lalu';
    if (elapsed.inHours < 24) return '${elapsed.inHours} jam lalu';
    return '${elapsed.inDays} hari lalu';
  }

  static String formatUnits(double count, String unit) {
    final formatted = NumberFormat('#,##0.##', 'id_ID').format(count);
    final suffix = unit.isEmpty ? '' : ' $unit';
    return '$formatted$suffix';
  }

  static String maskAccountNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 4) return digits;
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AssetPalette.forType(account.assetType, context);
    final hidden = isBalanceHidden;
    final value = account.marketValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: isActive ? 0 : 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors[0].withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -40,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(),
                const SizedBox(height: 6),
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidden
                          ? 'Rp ••••••'
                          : CurrencyInputFormatter.format(value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildMeta(hidden),
                const Spacer(),
                _buildFooter(context, colors, hidden),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        if (account.isInvestment) const _EmvChip() else const _CashChip(),
        const SizedBox(width: 8),
        _AssetBadge(assetType: account.assetType),
        const Spacer(),
        if (account.bankName.isNotEmpty)
          Flexible(
            child: Text(
              account.bankName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeta(bool hidden) {
    if (!account.isInvestment) {
      return const Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Saldo Rekening',
          style: TextStyle(color: Colors.white60, fontSize: 11),
        ),
      );
    }

    final chips = <Widget>[];

    if (account.unitCount > 0) {
      chips.add(
        _MetaChip(
          text: formatUnits(account.unitCount, account.effectiveUnitLabel),
        ),
      );
    }
    if (account.hasKnownPrice) {
      chips.add(
        _MetaChip(
          text: hidden
              ? '@ Rp ••••••/${account.effectiveUnitLabel}'
              : '@ ${CurrencyInputFormatter.format(account.lastMarketPrice)}/${account.effectiveUnitLabel}',
        ),
      );
    }
    if (account.lastBuybackPrice > 0 &&
        account.lastBuybackPrice < account.lastMarketPrice) {
      chips.add(
        _MetaChip(
          text: hidden
              ? 'Buyback Rp ••••••'
              : 'Buyback ${CurrencyInputFormatter.format(account.lastBuybackPrice)}',
        ),
      );
    }
    if (account.avgBuyPrice > 0 && account.unitCount > 0) {
      chips.add(_buildPlBadge(hidden));
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chips.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    chips[i],
                  ],
                ],
              ),
            ),
          if (account.hasKnownPrice && isPriceStale(account))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Harga terakhir: ${priceAgeLabel(account.priceFetchedAt!)}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlBadge(bool hidden) {
    final totalCost = account.unitCount * account.avgBuyPrice;
    final currentVal = account.marketValue;
    final pl = totalCost > 0
        ? ((currentVal - totalCost) / totalCost * 100)
        : 0.0;
    final isProfit = pl >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isProfit
            ? Colors.greenAccent.withOpacity(0.2)
            : Colors.redAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isProfit ? '+' : ''}${hidden ? '••' : pl.toStringAsFixed(2)}%',
        style: TextStyle(
          color: isProfit ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, List<Color> colors, bool hidden) {
    final String label;
    final String value;
    if (account.accountNumber.isNotEmpty) {
      label = account.accountHolderName.isEmpty
          ? 'Atas Nama'
          : account.accountHolderName.toUpperCase();
      value = hidden ? '••••••••' : maskAccountNumber(account.accountNumber);
    } else if (account.symbol.isNotEmpty) {
      label = 'Simbol';
      value = account.symbol.toUpperCase();
    } else {
      label = 'Jenis';
      value = _AssetBadge.labels[account.assetType] ?? '-';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            GestureDetector(
              onTap: onAddFunds,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Nabung',
                  style: TextStyle(
                    color: colors[0],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (account.accountNumber.isNotEmpty) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onCopyAccount,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy, color: Colors.white, size: 20),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CashChip extends StatelessWidget {
  const _CashChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 23,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        color: Colors.white,
        size: 15,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
