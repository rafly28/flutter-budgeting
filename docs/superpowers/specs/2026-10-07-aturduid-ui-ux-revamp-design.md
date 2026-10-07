---
title: "Aturduid UI/UX Revamp - Design Specification"
date: "2026-10-07"
tags: [aturduid, flutter, ui-ux, design-system, personal-finance, dribbble-shot-27479977]
status: "approved"
author: "Rimuru Tempest (Master Orchestrator)"
target_executor: "Kaijin (Code Craftsman)"
---

# 🎨 Aturduid UI/UX Revamp - Design Specification

> **Rujukan Desain**: Dribbble Shot 27479977 (*Budget Tracker App*)  
> **Ruang Lingkup**: Fase 1 (Sistem Tema Multi-Persona, Halaman Utama/Dashboard, Hero Balance Card, Alokasi 50-30-20, Menu Hub, dan Form Catat Transaksi).

---

## 1. Ringkasan Eksekutif

Dokumen ini memuat spesifikasi arsitektur antarmuka (UI/UX) dan sistem desain baru untuk aplikasi **Aturduid** (*flutter-budgeting*). Perombakan ini bertujuan mentransformasi antarmuka konvensional menjadi pengalaman *warm modern fintech* yang elegan, bebas dari *AI-slop*, serta mendukung **Dual-Persona Theme System** (Persona Maskulin Eksekutif untuk Master dan Persona Pastel Girly untuk Pasangan).

---

## 2. Sistem Tema Multi-Persona (5 Preset)

Sistem tema diintegrasikan ke dalam `UserSettings` (field `themeColor` & `themePreset`) dan `ThemeData` global di `main.dart` dengan *auto-contrast calculation* (`onPrimary` & `onSurface`):

| Preset ID | Nama Tema | Karakter / Persona | Primary & Accent | Background & Card Surface | Hero Gradient Style |
|:---|:---|:---|:---|:---|:---|
| `pink` | **Baby Pink Sakura** | Girly, lucu, manis, lembut (Favorit Pasangan) | Primary: `#FF758F`<br>Accent: `#FFAAA6` | Bg: `#FFF5F7`<br>Card: `#FFFFFF`<br>Border: `#FFE3E8` | `linear-gradient(135deg, #FF758F, #FFAAA6)` |
| `midnight` | **Midnight Stealth** | Laki gagah, maskulin, dark executive (Master) | Primary: `#FB5B0E`<br>Accent: `#DE8D43` | Bg: `#0B0605`<br>Card: `#161616`<br>Border: `#262626` | `linear-gradient(135deg, #0F172A, #1E293B)` |
| `warm` | **Warm Editorial** | Dribbble Fintech Standard, clean warm cream | Primary: `#FB5B0E`<br>Accent: `#5B5B5C` | Bg: `#F1F1F0`<br>Card: `#FFFFFF`<br>Border: `#E5E5E3` | `linear-gradient(135deg, #1C1917, #292524)` |
| `lilac` | **Lilac Dream** | Girly pastel estetik, tenang | Primary: `#A370F7`<br>Accent: `#CDB4DB` | Bg: `#F8F6FF`<br>Card: `#FFFFFF`<br>Border: `#EADBFC` | `linear-gradient(135deg, #8E54E9, #A370F7)` |
| `emerald` | **Forest Emerald** | Earthy, stabil, natural | Primary: `#10B981`<br>Accent: `#059669` | Bg: `#F0FDF4`<br>Card: `#FFFFFF`<br>Border: `#D1FAE5` | `linear-gradient(135deg, #064E3B, #047857)` |

---

## 3. Arsitektur Komponen Layar Utama (Dashboard)

### 3.1 Header Terintegrasi
- **Kiri**: Subtitle Siklus Gajian (*"Siklus Gajian • Tgl 25"*) dan Sapaan Personal (*"Halo, [Nama/Panggilan]"*).
- **Kanan**: **User Avatar Button** berbentuk rounded box (14px radius) yang menampilkan huruf inisial nama pengguna (misal: `"R"`). Saat disentuh, membuka menu Setelan/Profil (mengeliminasi duplikasi tombol setting).

### 3.2 Hero Balance Card
- **Border Radius**: 24px dengan *ambient shadow* sesuai warna aksen.
- **Top Row**: Label *"Sisa Saldo Siklus Ini"* dan tombol mata privasi (`isBalanceHidden` toggle: `Rp ••••••••` vs nilai riil).
- **Nominal Saldo**: Font tebal 28-34px (*Plus Jakarta Sans / Bold 900*).
- **Budget Health Bar**: Bar tipis (6px) dengan indikator sisa persentase dan status dinamis:
  - Hijau (`#10B981`): Sisa > 60% (*"Sangat Terkendali"*).
  - Amber (`#F59E0B`): Sisa 20% - 60% (*"Terkendali"*).
  - Merah (`#FB2E11`): Sisa < 20% (*"Hampir Habis / Overbudget"*).
- **Split Metrik**: Dua kapsul transparan: **Pemasukan** (`↓ nominal`) dan **Pengeluaran** (`↑ nominal`).

### 3.3 Alokasi 50 - 30 - 20 (3 Mini Pocket Cards)
Tiga kartu mini sejajar (1 baris x 3 kolom) yang adaptif:
1. **Kebutuhan (50%)**: Badge Biru `50%`, nominal terpakai vs pagu, dan mini progress bar.
2. **Keinginan (30%)**: Badge Amber `30%`, nominal terpakai vs pagu, dan mini progress bar.
3. **Tabungan (20%)**: Badge Emerald `20%`, akumulasi tabungan siklus berjalan vs target bulanan (pola *monthly achievement checklist*).

### 3.4 Menu Hub (3 Utama + 1 Box "...")
Menggantikan bilah navigasi bawah (*bottom dock eliminated*) untuk memberikan tampilan *full-screen*:
- Label Header: **"Menu"**
- Grid 4 Slot:
  1. `[📑 Riwayat]`: Navigasi langsung ke `HistoryPage`.
  2. `[💼 Tabungan]`: Navigasi langsung ke `SavingPage`.
  3. `[📊 Statistik]`: Navigasi langsung ke `StatisticPage`.
  4. `[••• Lainnya]`: Membuka modal bottom sheet berisi menu lengkap:
     - `[🎯 Anggaran]` (`CategoryManagementPage` / Budget Limit)
     - `[⇄ Transfer]` (Modal Transfer antar rekening)
     - `[💳 Hutang]` (`DebtPage`)
     - `[📅 Rencana]` (`PlanningPage`)
     - `[📂 Kategori]` (Kelola Kategori)
     - `[📥 Export PDF]` (PDF Service)
     - `[☁️ Backup]` (Backup/Restore Database)
     - `[⚙️ Setelan]` (`SettingsPage`)

### 3.5 Feed Transaksi Terkini
- Menampilkan 3-5 transaksi terbaru dalam siklus.
- Format teks standar:
  - **Judul Utama**: `expense.note` (Catatan transaksi, misal *"Matcha Latte & Toast"*).
  - **Subtitle**: `[Kategori] - [Deskripsi/Tempat] - [Sumber Rekening]` (misal *"Makan & Minum - Cafe Sore - BCA Utama"*).
  - **Nominal Trailing**: Semantic colored (`-Rp 45.000` merah untuk expense, `+Rp 11.500.000` hijau untuk income, biru untuk transfer).

### 3.6 Floating Action Button (FAB)
- Tombol kapsul melayang di bagian bawah tengah: `[＋ Catat Transaksi]`.
- Saat ditekan, membuka form **Catat Transaksi** secara mulus.

---

## 4. Arsitektur Form Catat Transaksi (`AddExpensePage`)

1. **Header**: Tombol kembali (`←`), judul *"Catat Transaksi"*.
2. **Segmented Type Switcher**: 4 Tab pill: `Pengeluaran`, `Pemasukan`, `Transfer`, `Hutang`.
3. **Hero Nominal Card**:
   - Tampilan angka besar (*bold 32px*) dengan format mata uang otomatis.
   - Quick Amount Chips: `+10rb`, `+50rb`, `+100rb`, `+500rb`.
4. **Form Group Card**:
   - **Pilih Kategori**: Grid pill kategori interaktif dengan ikon visual.
   - **Sumber Dana & Rekening Tujuan**: Dropdown selector yang bersih.
   - **Tanggal**: Date picker capsule dengan nilai default hari ini.
   - **Catatan / Keterangan**: Text field dengan placeholder intuitif.
5. **Tombol Simpan**: Lebar penuh di bagian bawah `[Simpan Transaksi]`.

---

## 5. Keputusan Teknis & Anti AI-Slop Checklist

- [x] **Zero Decorative Emojis**: Bebas dari emoji pada komponen inti operasional.
- [x] **Preserve Payday Reset Model**: Perhitungan sisa saldo dan alokasi 50-30-20 tetap terikat pada tanggal gajian (`payday`), bukan bulan kalender kaku.
- [x] **Non-blocking Startup**: Semua inisialisasi Hive dan service async tidak menghalangi `runApp()`.
- [x] **High Contrast Typography**: Dynamic text styling (`onPrimary` / `onSurface`) menjamin keterbacaan pada tema gelap maupun tema pastel terang.
