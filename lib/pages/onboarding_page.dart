import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/user_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  int _selectedPayday = 1; // Default tanggal 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 ILUSTRASI/HEADER
              const Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                "Selamat Datang di\nAturDuid",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Mari siapkan profil keuanganmu agar laporan lebih akurat.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // 🔹 INPUT NAMA
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Nama Panggilan",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 INPUT TANGGAL GAJIAN (TUTUP BUKU)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.grey),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "Tanggal Gajian / Tutup Buku:",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _selectedPayday,
                      underline: const SizedBox(),
                      items: List.generate(28, (index) => index + 1)
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text("Tgl $e"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPayday = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "*Ini berguna untuk mereset perhitungan budget dan statistik setiap bulannya secara otomatis.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // 🔹 TOMBOL MULAI
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Nama tidak boleh kosong!")),
                    );
                    return;
                  }

                  // Simpan Nama dan Tanggal Payday ke Controller
                  final userCtrl = context.read<UserController>();
                  userCtrl.setUser(_nameController.text.trim());
                  userCtrl.setPayday(_selectedPayday);

                  // Arahkan ke Dashboard
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text(
                  "Mulai Perjalanan Finansialku",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
