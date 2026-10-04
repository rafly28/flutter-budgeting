import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/saving_controller.dart';
import '../controllers/budget_controller.dart';
import '../utils/currency_input_formatter.dart';
import 'dashboard_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  int _selectedPayday = 1;
  bool _resetBalanceOnPayday = false;
  final TextEditingController _initialBalanceCtrl = TextEditingController();
  final TextEditingController _foodBudgetCtrl = TextEditingController();
  final TextEditingController _transportBudgetCtrl = TextEditingController();

  Future<void> _finishOnboarding() async {
    final userCtrl = context.read<UserController>();
    final savingCtrl = context.read<SavingController>();
    final budgetCtrl = context.read<BudgetController>();

    userCtrl.setUser(_nameController.text.trim());
    userCtrl.setPayday(_selectedPayday);
    userCtrl.toggleResetBalance(_resetBalanceOnPayday);

    final cleanBalance = _initialBalanceCtrl.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final double balance = double.tryParse(cleanBalance) ?? 0.0;
    if (balance > 0) {
      await savingCtrl.addSavingAccount(
        "Dompet Utama",
        balance,
        "Cash",
        "",
        "",
      );
    }

    final cleanFood = _foodBudgetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanTransport = _transportBudgetCtrl.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (cleanFood.isNotEmpty) {
      budgetCtrl.setBudgetLimit("Makanan", double.tryParse(cleanFood) ?? 0.0);
    }
    if (cleanTransport.isNotEmpty) {
      budgetCtrl.setBudgetLimit(
        "Transportasi",
        double.tryParse(cleanTransport) ?? 0.0,
      );
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [_buildPage1(), _buildPage2(), _buildPage3()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage == 0 && _nameController.text.isEmpty) {
                      return;
                    }
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage == 2 ? "Mulai Aplikasi" : "Selanjutnya",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 80,
            color: Colors.amber.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            "Selamat Datang!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Nama Panggilan Anda",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Text(
            "Tanggal Gajian",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext builder) {
                  return Container(
                    height: 250,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              child: const Text('Batal'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text('Simpan'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: _selectedPayday - 1,
                            ),
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                _selectedPayday = index + 1;
                              });
                            },
                            children: List<Widget>.generate(31, (int index) {
                              return Center(
                                child: Text(
                                  'Tanggal ${index + 1}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tanggal $_selectedPayday", style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              title: const Text("Mode Saldo: Reset Tiap Gajian", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Aktifkan jika ingin saldo di-reset jadi 0 tiap tanggal gajian. Jika mati, saldo berlanjut seperti m-Banking.", style: TextStyle(fontSize: 12)),
              value: _resetBalanceOnPayday,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => setState(() => _resetBalanceOnPayday = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 80,
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            "Saldo Saat Ini",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _initialBalanceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Rp 0",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_rounded, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 20),
          const Text(
            "Atur Limit Budget",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _foodBudgetCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              labelText: "Limit Makanan",
              prefixText: "Rp ",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _transportBudgetCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              labelText: "Limit Transportasi",
              prefixText: "Rp ",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
