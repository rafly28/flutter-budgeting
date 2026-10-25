import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aturduid/models/saving_account.dart';
import 'package:aturduid/widgets/saving_card.dart';

Widget _wrap(SavingAccount account, {bool hidden = false}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1E3A8A),
    ),
    home: Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SizedBox(
          width: 330,
          height: 224,
          child: SavingCard(
            account: account,
            isActive: true,
            isBalanceHidden: hidden,
            onAddFunds: () {},
            onCopyAccount: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('maskAccountNumber menampilkan 4 digit terakhir', () {
    expect(SavingCard.maskAccountNumber('1234567890'), '•••• 7890');
    expect(SavingCard.maskAccountNumber('1234'), '1234');
    expect(SavingCard.maskAccountNumber('0812 3456 7890'), '•••• 7890');
  });

  testWidgets('kartu tunai tampil tanpa overflow', (tester) async {
    final account = SavingAccount(
      name: 'Tabungan Darurat',
      balance: 5000000,
      bankName: 'BCA',
      accountNumber: '1234567890',
      accountHolderName: 'Budi',
    );

    await tester.pumpWidget(_wrap(account));

    expect(find.text('Tabungan Darurat'), findsOneWidget);
    expect(find.textContaining('5.000.000'), findsOneWidget);
    expect(find.text('•••• 7890'), findsOneWidget);
    expect(find.text('Nabung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kartu emas dengan buyback, P/L, dan harga basi', (tester) async {
    final account = SavingAccount(
      name: 'Logam Mulia',
      balance: 10000000,
      assetType: 'gold',
      unitCount: 5,
      avgBuyPrice: 2000000,
      lastMarketPrice: 2500000,
      lastBuybackPrice: 2400000,
      priceFetchedAt: DateTime.now().subtract(const Duration(hours: 10)),
    );

    await tester.pumpWidget(_wrap(account));

    expect(find.text('Logam Mulia'), findsOneWidget);
    expect(find.textContaining('5 gram'), findsOneWidget);
    expect(find.textContaining('2.500.000/gram'), findsOneWidget);
    expect(find.textContaining('Buyback'), findsOneWidget);
    expect(find.textContaining('+25.00%'), findsOneWidget);
    expect(find.textContaining('Harga terakhir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kartu kripto tanpa baris buyback', (tester) async {
    final account = SavingAccount(
      name: 'Bitcoin',
      balance: 1000000,
      assetType: 'crypto',
      symbol: 'bitcoin',
      unitCount: 0.01,
      avgBuyPrice: 900000000,
      lastMarketPrice: 900000000,
      lastBuybackPrice: 900000000,
      priceFetchedAt: DateTime.now(),
    );

    await tester.pumpWidget(_wrap(account));

    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.textContaining('KRIPTO'), findsOneWidget);
    expect(find.textContaining('Buyback'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kartu saham tampil tanpa overflow', (tester) async {
    final account = SavingAccount(
      name: 'Saham BBCA',
      balance: 15000000,
      assetType: 'stock',
      symbol: 'BBCA.JK',
      unitCount: 10,
      avgBuyPrice: 9500000,
      lastMarketPrice: 10000000,
      lastBuybackPrice: 10000000,
      priceFetchedAt: DateTime.now(),
    );

    await tester.pumpWidget(_wrap(account));

    expect(find.text('Saham BBCA'), findsOneWidget);
    expect(find.textContaining('SAHAM'), findsOneWidget);
    expect(find.textContaining('10 lot'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('investasi tanpa harga tetap tampil rapi', (tester) async {
    final account = SavingAccount(
      name: 'Emas Belum Update',
      balance: 3000000,
      assetType: 'gold',
      unitCount: 2,
      avgBuyPrice: 1500000,
    );

    await tester.pumpWidget(_wrap(account));

    expect(find.text('Emas Belum Update'), findsOneWidget);
    expect(find.textContaining('2 gram'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mode privasi menyembunyikan nilai dan nomor', (tester) async {
    final account = SavingAccount(
      name: 'Dompet',
      balance: 5000000,
      bankName: 'Mandiri',
      accountNumber: '1234567890',
      accountHolderName: 'Siti',
    );

    await tester.pumpWidget(_wrap(account, hidden: true));

    expect(find.text('Rp ••••••'), findsOneWidget);
    expect(find.text('••••••••'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nominal besar tidak melebar keluar kartu', (tester) async {
    final account = SavingAccount(
      name: 'Dana Besar',
      balance: 1234567890,
      bankName: 'BCA',
      accountNumber: '9876543210',
      accountHolderName: 'Andi',
    );

    await tester.pumpWidget(_wrap(account));

    expect(find.textContaining('1.234.567.890'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
