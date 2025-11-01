import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/expense_controller.dart';
import 'controllers/user_controller.dart';
import 'models/expense.dart';
import 'models/monthly_report.dart';
import 'models/user_profile.dart';
import 'pages/dashboard_page.dart';
import 'pages/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init intl locale
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(MonthlyReportAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  await Hive.openBox<Expense>('expensesBox');
  await Hive.openBox<MonthlyReport>('monthlyReportsBox');
  await Hive.openBox<UserProfile>('userBox');

  final userBox = Hive.box<UserProfile>('userBox');
  final hasUser = userBox.isNotEmpty;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseController()),
        ChangeNotifierProvider(create: (_) => UserController()),
      ],
      child: MainApp(hasUser: hasUser),
    ),
  );
}

class MainApp extends StatelessWidget {
  final bool hasUser;
  const MainApp({super.key, required this.hasUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: hasUser ? "/dashboard" : "/onboarding",
      routes: {
        "/dashboard": (_) => const DashboardPage(),
        "/onboarding": (_) => const OnboardingPage(),
      },
    );
  }
}
