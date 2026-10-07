# Aturduid UI/UX Revamp Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Mengimplementasikan perombakan sistem antarmuka (UI/UX) Aturduid berbasis Dribbble Shot 27479977 dengan dukungan Dual-Persona 5 Preset Tema, Full-Screen Clean Dashboard, 50-30-20 Mini Pocket Cards, Menu Hub, dan Form Catat Transaksi Modern.

**Architecture:** Menerapkan arsitektur desain berbasis komponen (*component-driven*) di Flutter:
1. `AppThemes` sebagai sentral konfigurasi tema multi-persona dengan auto-contrast calculation.
2. Komponen mandiri terisolasi: `FinanceSummaryCard` (Hero Balance), `AllocationPocketCards` (50-30-20 Radar), `MenuHubWidget` & `MoreMenuBottomSheet` (Navigasi Modul), dan `AddExpensePage` (Form Transaksi).
3. Eliminasi bottom navigation dock lama untuk tampilan *full-screen clean canvas* dengan bottom floating action pill.

**Tech Stack:** Flutter 3.x, Dart, Provider (State Management), Hive (Local Storage), Google Fonts (`Plus Jakarta Sans`), Flutter Animate.

---

### Task 1: Create Multi-Persona Theme System (`AppThemes`)

**Objective:** Membuat sentral definisi 5 preset tema (Baby Pink Sakura, Midnight Stealth, Warm Editorial, Lilac Dream, Forest Emerald) dengan skema warna dan helper gradien hero card.

**Files:**
- Create: `lib/utils/app_themes.dart`
- Test: `test/app_themes_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aturduid/utils/app_themes.dart';

void main() {
  test('AppThemes should define 5 presets and resolve correct theme data', () {
    expect(AppThemes.presets.length, 5);
    final pinkTheme = AppThemes.getThemeData('pink');
    expect(pinkTheme.useMaterial3, isTrue);
    expect(AppThemes.getHeroGradient('pink'), isNotNull);
  });
}
```

**Step 2: Run test to verify failure**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/app_themes_test.dart"`
Expected: FAIL — "Target of URI doesn't exist: 'package:aturduid/utils/app_themes.dart'"

**Step 3: Write minimal implementation**

Buat `lib/utils/app_themes.dart` dengan class `AppThemePreset` dan map 5 preset warna, background, card, text, dan gradien hero card.

**Step 4: Run test to verify pass**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/app_themes_test.dart"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/utils/app_themes.dart test/app_themes_test.dart
git commit -m "feat(theme): add AppThemes multi-persona preset definition"
```

---

### Task 2: Revamp Hero Balance Card (`FinanceSummaryCard`)

**Objective:** Memperbarui `FinanceSummaryCard` agar mendukung gradien tema adaptif, masking saldo privasi, slim budget progress bar dinamis, dan split metrik pemasukan vs pengeluaran.

**Files:**
- Modify: `lib/widgets/finance_summary_card.dart`
- Test: `test/widgets/finance_summary_card_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aturduid/widgets/finance_summary_card.dart';

void main() {
  testWidgets('FinanceSummaryCard displays balance, budget bar, and income/expense metrics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinanceSummaryCard(
            balance: 7850000,
            income: 11500000,
            expense: 3650000,
            isHidden: false,
            presetId: 'pink',
          ),
        ),
      ),
    );

    expect(find.textContaining('7.850.000'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify failure**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/widgets/finance_summary_card_test.dart"`
Expected: FAIL

**Step 3: Write minimal implementation**

Perbarui `lib/widgets/finance_summary_card.dart` sesuai spesifikasi Dribbble (sudut 24px, lingkaran aksen halus, tipografi 28-34px, slim bar 6px).

**Step 4: Run test to verify pass**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/widgets/finance_summary_card_test.dart"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/widgets/finance_summary_card.dart test/widgets/finance_summary_card_test.dart
git commit -m "feat(ui): revamp FinanceSummaryCard with adaptive theme gradient and metrics"
```

---

### Task 3: Implement 50-30-20 Mini Pocket Cards Widget

**Objective:** Membuat komponen `AllocationPocketCards` yang menampilkan 3 kartu mini horizontal untuk Kebutuhan (50%), Keinginan (30%), dan Tabungan (20%).

**Files:**
- Create: `lib/widgets/allocation_pocket_cards.dart`
- Test: `test/widgets/allocation_pocket_cards_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aturduid/widgets/allocation_pocket_cards.dart';

void main() {
  testWidgets('AllocationPocketCards displays 3 pocket cards (Needs, Wants, Savings)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AllocationPocketCards(
            needsSpent: 2400000,
            needsBudget: 5750000,
            wantsSpent: 850000,
            wantsBudget: 3450000,
            savingsCurrent: 2000000,
            savingsTarget: 2300000,
          ),
        ),
      ),
    );

    expect(find.text('Kebutuhan'), findsOneWidget);
    expect(find.text('Keinginan'), findsOneWidget);
    expect(find.text('Tabungan'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify failure**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/widgets/allocation_pocket_cards_test.dart"`
Expected: FAIL

**Step 3: Write minimal implementation**

Buat `lib/widgets/allocation_pocket_cards.dart` dengan row 3 expanded card, badge persentase, nominal ringkas, dan mini track progress.

**Step 4: Run test to verify pass**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/widgets/allocation_pocket_cards_test.dart"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/widgets/allocation_pocket_cards.dart test/widgets/allocation_pocket_cards_test.dart
git commit -m "feat(ui): add AllocationPocketCards widget for 50-30-20 budget tracking"
```

---

### Task 4: Implement Menu Hub & More Bottom Sheet

**Objective:** Membuat widget `MenuHubWidget` dengan 4 slot (Riwayat, Tabungan, Statistik, Lainnya) serta bottom sheet modal `MoreMenuBottomSheet` untuk membuka seluruh menu sekunder.

**Files:**
- Create: `lib/widgets/menu_hub_widget.dart`
- Create: `lib/widgets/more_menu_bottom_sheet.dart`
- Test: `test/widgets/menu_hub_widget_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aturduid/widgets/menu_hub_widget.dart';

void main() {
  testWidgets('MenuHubWidget renders Riwayat, Tabungan, Statistik, and Lainnya', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MenuHubWidget(),
        ),
      ),
    );

    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Tabungan'), findsOneWidget);
    expect(find.text('Statistik'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify failure**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/widgets/menu_hub_widget_test.dart"`
Expected: FAIL

**Step 3: Write minimal implementation**

Buat `lib/widgets/menu_hub_widget.dart` dan `lib/widgets/more_menu_bottom_sheet.dart` dengan integrasi navigasi ke route masing-masing (`/history`, `/saving`, `/statistic`, `/planning`, `/debt`, `/category-management`, `/settings`).

**Step 4: Run test to verify pass**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/widgets/menu_hub_widget_test.dart"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/widgets/menu_hub_widget.dart lib/widgets/more_menu_bottom_sheet.dart test/widgets/menu_hub_widget_test.dart
git commit -m "feat(ui): add MenuHubWidget and MoreMenuBottomSheet"
```

---

### Task 5: Revamp `DashboardPage` (Full-Screen Layout & Floating FAB)

**Objective:** Mengintegrasikan seluruh komponen baru pada `DashboardPage` (Header Avatar Inisial, Hero Card, 50-30-20 Mini Cards, Menu Hub, Recent Transactions, Floating Action Button `[＋ Catat Transaksi]`, dan menghapus dock lama).

**Files:**
- Modify: `lib/pages/dashboard_page.dart`
- Test: `test/pages/dashboard_page_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aturduid/pages/dashboard_page.dart';
import 'package:aturduid/controllers/user_controller.dart';
import 'package:aturduid/controllers/expense_controller.dart';
import 'package:aturduid/controllers/category_controller.dart';
import 'package:aturduid/controllers/budget_controller.dart';
import 'package:aturduid/controllers/saving_controller.dart';
import 'package:aturduid/controllers/plan_controller.dart';

void main() {
  testWidgets('DashboardPage renders clean header, hero, menu hub, and floating FAB', (tester) async {
    // Setup mock providers and pump DashboardPage
    // Verify floating action button 'Catat Transaksi' exists
  });
}
```

**Step 2: Run test to verify failure**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/pages/dashboard_page_test.dart"`
Expected: FAIL

**Step 3: Write minimal implementation**

Perbarui `lib/pages/dashboard_page.dart` dengan struktur clean canvas baru tanpa bottom navigation bar lama.

**Step 4: Run test to verify pass**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/pages/dashboard_page_test.dart"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/pages/dashboard_page.dart test/pages/dashboard_page_test.dart
git commit -m "feat(ui): revamp DashboardPage to full-screen modern fintech layout"
```

---

### Task 6: Revamp `AddExpensePage` (Modern Form & Quick Chips)

**Objective:** Mengubah tata letak form transaksi menjadi antarmuka modern dengan pill switcher, nominal hero card berukuran besar, quick amount chips, dan grid kategori.

**Files:**
- Modify: `lib/pages/add_expense_page.dart`
- Test: `test/pages/add_expense_page_test.dart`

**Step 1: Write failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aturduid/pages/add_expense_page.dart';

void main() {
  testWidgets('AddExpensePage renders type switcher, amount input, and category pills', (tester) async {
    // Pump AddExpensePage and verify elements
  });
}
```

**Step 2: Run test to verify failure**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/pages/add_expense_page_test.dart"`
Expected: FAIL

**Step 3: Write minimal implementation**

Perbarui `lib/pages/add_expense_page.dart` dengan header kembali, type switcher tab (`Pengeluaran`, `Pemasukan`, `Transfer`, `Hutang`), nominal display, dan full-width submit button.

**Step 4: Run test to verify pass**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test test/pages/add_expense_page_test.dart"`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/pages/add_expense_page.dart test/pages/add_expense_page_test.dart
git commit -m "feat(ui): revamp AddExpensePage with modern type switcher and amount hero card"
```

---

### Task 7: Update `SettingsPage` Theme Selector

**Objective:** Memperbarui pemilih tema di `SettingsPage` agar menampilkan 5 pilihan preset baru (Baby Pink Sakura, Midnight Stealth, Warm Editorial, Lilac Dream, Forest Emerald) dengan preview warna yang jelas.

**Files:**
- Modify: `lib/pages/settings_page.dart`

**Step 1: Write test & verify failure**
**Step 2: Update `_buildColorOption` & preset list di `settings_page.dart`**
**Step 3: Verify test passes**
**Step 4: Commit**

```bash
git add lib/pages/settings_page.dart
git commit -m "feat(settings): update theme selector to support 5 multi-persona presets"
```

---

### Task 8: Full Integration Test & Build Verification

**Objective:** Memverifikasi seluruh unit test lolos tanpa regresi dan memastikan aplikasi terkompilasi bersih (`flutter build apk --release`).

**Files:**
- Verify: `test/`
- Build target: `build/app/outputs/flutter-apk/app-release.apk`

**Step 1: Run complete test suite**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter test"`
Expected: ALL TESTS PASS

**Step 2: Build release APK**

Run: `wsl -d Ubuntu -e bash -c "cd /home/fly/project/flutter-budgeting && /home/fly/.android/flutter/bin/flutter build apk --release --no-tree-shake-icons"`
Expected: Build successful, copy APK to `C:\Users\Rafly\Downloads\Aturduid-release.apk`.

**Step 3: Commit**

```bash
git add .
git commit -m "chore: verify tests and complete UI/UX revamp release build"
```
