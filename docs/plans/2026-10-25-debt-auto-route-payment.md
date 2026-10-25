# Rencana: Auto-Route Pembayaran Hutang/Piutang ke Akun Asal

**Konteks:** Saat membuat catatan piutang, sumber dana yang dipilih (mis. Tabungan A) hanya tersimpan pada baris ledger utama tertaut (`Expense.debtId` + `source`), bukan pada model `Debt`. Karena itu dialog pembayaran (`_showPayDialog` di `lib/pages/debt_page.dart:305-503`) selalu meminta pemilihan akun manual (default `'Budget Utama'`). Fitur ini mengambil akun asal dari ledger lalu menyediakan checkbox (default ON) agar pembayaran otomatis rute ke akun asal.

**Keputusan yang disetujui user:**
- Pendekatan A — lookup dari ledger, tanpa perubahan skema Hive.
- Checkbox default AKTIF ketika akun asal ditemukan; dimatikan → dropdown manual muncul (perilaku lama).
- Berlaku untuk piutang (dana masuk ke asal) **dan** hutang (dana ditarik dari tujuan awal pinjaman).
- Naikkan versi `pubspec.yaml` saat build: basis worktree `0.2.13+2` → **`0.2.15+1`**.

**Kendala global:**
- Kerja terisolasi di worktree `.worktrees/feat-debt-auto-route` (branch `feat/debt-auto-route`); main checkout tidak disentuh.
- Signatur & logika `payDebt` TIDAK diubah (hanya terima `accountName` yang sudah di-resolve dialog).
- Tanpa migrasi skema Hive, tanpa backfill, form pembuatan (`add_expense_page.dart`) tidak disentuh.
- TDD: tulis tes dulu → lihat gagal → implementasi → hijau; commit gaya repo (`feat:`/`chore:`/`docs:`).

---

## Task 1: Helper `principalAccountOf(Debt)` di DebtController

**Files:** Edit `lib/controllers/debt_controller.dart`; Create `test/debt_auto_route_test.dart`.

**Step 1 (RED):** Buat `test/debt_auto_route_test.dart` meniru setup `test/accounting_regression_test.dart:15-61` (adapters 0,2,7,9; box `savingsBox`/`expensesBox`/`monthlyReportsBox`/`debtBox` di temp dir; `SavingController` → `ExpenseController` → `DebtController`). Tiga kasus:

- `principalAccountOf mengembalikan akun asal utang tertaut` — `addSaving('Tabungan A', 1000)`, `debtController.addDebt(piutang 400, 'Tabungan A')` → ekspektasi `'Tabungan A'`.
- `principalAccountOf mengembalikan tujuan awal untuk hutang` — `addDebt(hutang 500, 'Tabungan A')` → `'Tabungan A'`.
- `principalAccountOf null bila tidak ada ledger utama tertaut` — `Hive.box<Debt>('debtBox').put(id, debt)` langsung tanpa expense → `null`.

Jalankan `flutter test test/debt_auto_route_test.dart`.
**Expected:** compilation error ("Method 'principalAccountOf' isn't defined") = RED karena fitur belum ada.

**Step 2 (GREEN):** Tambahkan di `debt_controller.dart` (letak: setelah `deleteDebt`, sebelum `_isValidDebt`):

```dart
String? principalAccountOf(Debt debt) {
  final principalMatches = _expenseController.expenses
      .where(
        (expense) =>
            expense.debtId == debt.id && _matchesPrincipal(expense, debt),
      )
      .toList();
  return principalMatches.length == 1 ? principalMatches.single.source : null;
}
```

Jalankan lagi file tes tersebut.
**Expected:** `All tests passed!`.

**Step 3:** `git add test/debt_auto_route_test.dart lib/controllers/debt_controller.dart && git commit -m "feat: helper principalAccountOf untuk akun asal debt"`.

---

## Task 2: Checkbox rute otomatis di dialog pembayaran

**Files:** Edit `lib/pages/debt_page.dart` (`_showPayDialog`); Create `test/widgets/debt_pay_dialog_test.dart`.

**Konsumsi dari Task 1:** `DebtController.principalAccountOf(Debt)` sinkron → `String?`.

**Step 1 (RED):** Widget test `test/widgets/debt_pay_dialog_test.dart`:

- Setup: sama seperti Task 1 + `MultiProvider` (`ChangeNotifierProvider.value` untuk `SavingController`, `ExpenseController`, `DebtController`) di atas `MaterialApp(home: DebtPage)`.
- Kasus A (piutang, checkbox ON): `addSaving('Tabungan A', 1000)`; `addDebt(piutang 400, 'Tabungan A')`; pump; tap tombol `Terima Pembayaran`; pumpAndSettle; ekspektasi: `find.text('Terima ke sumber dana asal (Tabungan A)')` ada; `Checkbox` state on; `DropdownButtonFormField<String>` **tidak ada**; enterText Nominal `400`; tap `Simpan`; pumpAndSettle; ekspektasi `balanceFor('Tabungan A') == 1000` (1000 − 400 utang −0 + 400 kembali) dan `balanceFor('Budget Utama')` tidak berubah.
- Kasus B (checkbox dimatikan): setup sama; buka dialog; tap checkbox untuk off; endpoint dropdown muncul (`find.byType(DropdownButtonFormField<String>)` satu); bayar 200 ke `'Budget Utama'` (default dropdown) → main +200; Tabungan A tetap 600.
- Kasus C (tanpa ledger utama): debt langsung `box.put` tanpa expense → dialog tanpa checkbox, dropdown tampil (fallback). 

Jalankan `flutter test test/widgets/debt_pay_dialog_test.dart`.
**Expected:** RED — checkbox belum ada di dialog (finder gagal).

**Step 2 (GREEN):** Di `_showPayDialog`:

```dart
final originAccount = ctrl.principalAccountOf(debt); // sebelum showDialog
var autoToOrigin = originAccount != null;
```

Dalam builder:
- `final targetAccount = (autoToOrigin && originAccount != null) ? originAccount : selectedAccount;`
- `accountBalance` memakai `balanceFor(targetAccount)`.
- Ganti blok label+dropdown (baris 371-410) menjadi kondisional:

```dart
if (originAccount != null) ...[
  CheckboxListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: autoToOrigin,
    title: Text(
      isOutgoing
          ? 'Bayar dari akun tujuan awal ($originAccount)'
          : 'Terima ke sumber dana asal ($originAccount)',
    ),
    onChanged: isSaving
        ? null
        : (val) => setDialogState(() => autoToOrigin = val ?? false),
  ),
] else ...[
  Text(accountLabel, /* gaya lama */),
  const SizedBox(height: 6),
],
if (originAccount == null || !autoToOrigin)
  DropdownButtonFormField<String>( /* kode lama utuh */ ),
```

- Validasi saldo (baris 458-464) dan `ctrl.payDebt(debt, amount, selectedAccount)` (baris 467-471) berubah memakai `targetAccount`, pesan toast `'Saldo $targetAccount tidak mencukupi.'`.

**Expected:** ketiga kasus `All tests passed!`; lalu jalankan seluruh suite `flutter test` (baseline 43 + baru).
**Expected:**`All tests passed!`.

**Step 3:** `git add lib/pages/debt_page.dart test/widgets/ && git commit -m "feat: checkbox rute otomatis ke akun asal pada pembayaran debt"`.

---

## Task 3: Bump versi + verifikasi penuh

**Files:** Edit `pubspec.yaml` (baris 4).

**Step 1:** `version: 0.2.13+2` → `version: 0.2.15+1`. (Perubahan konfigurasi — pengecualian TDD, tidak ada tes.)

**Step 2:** `flutter analyze` → **Expected:** `No issues found!`. Lalu `flutter test` → **Expected:** `All tests passed!`.

**Step 3:** `git add pubspec.yaml && git commit -m "chore: bump versi aplikasi ke 0.2.15+1"`.

---

## Review Focus (input yang tidak dilatih tes)

1. Debt dengan Ledger utama ganda/ambigu → helper `null` (dropdown manual) — pastikan tidak crash.
2. Akun asal adalah aset investasi (emas/kripto) — aliran masuk lewat `applyInvestmentFlow` (sudah dipakai fitur lain, bukan kode baru; cukup dipastikan rute tidak memilih akun investasi secara salah).
3. Dialog untuk debt `isSettled` (tombol bayar disembunyikan?) — perilaku lama tidak boleh berubah.
4. `onChange` checkbox saat `isSaving` — tidak boleh bisa diubah saat proses simpan.
5. Toast/preview saldo tetap informatif setelah dropdown disembunyikan.
