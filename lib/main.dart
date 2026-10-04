import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:toastification/toastification.dart';

import 'controllers/expense_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/budget_controller.dart';
import 'controllers/saving_controller.dart';
import 'controllers/plan_controller.dart';
import 'models/expense.dart';
import 'models/monthly_report.dart';
import 'models/user_profile.dart';
import 'models/user_settings.dart';
import 'models/transaction_category.dart';
import 'models/category_budget.dart';
import 'models/saving_account.dart';
import 'models/plan_item.dart';
import 'models/debt.dart';
import 'pages/dashboard_page.dart';
import 'pages/onboarding_page.dart';
import 'services/notification_service.dart';
import 'controllers/debt_controller.dart';

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
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(TransactionCategoryAdapter());
  Hive.registerAdapter(CategoryBudgetAdapter());
  Hive.registerAdapter(SavingAccountAdapter());
  Hive.registerAdapter(PlanItemAdapter());
  Hive.registerAdapter(DebtAdapter());
  await Hive.openBox<SavingAccount>('savingsBox');
  await Hive.openBox<CategoryBudget>('budgetBox');
  await Hive.openBox<TransactionCategory>('categoryBox');
  // FIX: deleteBoxFromDisk dihapus — merusak settings setiap cold start
  await Hive.openBox<UserSettings>('userSettingsBox');
  await Hive.openBox<Expense>('expensesBox');
  await Hive.openBox<MonthlyReport>('monthlyReportsBox');
  await Hive.openBox<UserProfile>('userBox');
  await Hive.openBox<PlanItem>('planBox');
  await Hive.openBox<Debt>('debtBox');

  final userBox = Hive.box<UserProfile>('userBox');
  final hasUser = userBox.isNotEmpty;

  // FIX: Wrap NotificationService dalam try-catch agar tidak blocking startup.
  // init() yang throw akan menyebabkan runApp() tidak dipanggil → stuck di splash.
  try {
    await NotificationService.init();
    final settingsBox = Hive.box<UserSettings>('userSettingsBox');
    final isNotifyEnabled = settingsBox.isNotEmpty
        ? (settingsBox.getAt(0)?.isNotificationEnabled ?? true)
        : true;

    if (isNotifyEnabled) {
      // fire-and-forget intentional, tidak perlu await
      NotificationService.scheduleDailyReminder().catchError((_) {});
    } else {
      NotificationService.cancelNotification().catchError((_) {});
    }
  } catch (e) {
    // Notifikasi gagal init — app tetap jalan tanpa notifikasi
    debugPrint('NotificationService init failed (non-fatal): ');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavingController()),
        ChangeNotifierProvider(
          create: (context) =>
              ExpenseController(context.read<SavingController>()),
        ),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProvider(create: (_) => BudgetController()),
        ChangeNotifierProvider(create: (_) => PlanController()),
        ChangeNotifierProxyProvider<ExpenseController, DebtController>(
          lazy: false,
          create: (context) =>
              DebtController(context.read<ExpenseController>()),
          update: (context, expenseController, previous) =>
              previous ?? DebtController(expenseController),
        ),
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
    final userController = context.watch<UserController>();
    final primaryColor = Color(userController.themeColor);
    // Tema pastel (Baby Pink, Peach, dll) butuh teks gelap agar terbaca
    final isLight = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.light;
    final onPrimary = isLight ? const Color(0xFF1E293B) : Colors.white;

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F172A),
            primary: primaryColor,
            onPrimary: onPrimary,
            secondary: const Color(0xFF3B82F6),
            surface: Colors.grey.shade50,
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: onPrimary,
            elevation: 0,
            centerTitle: true,
            systemOverlayStyle: isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: primaryColor,
            foregroundColor: onPrimary,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: onPrimary,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
          ),
        ),
        initialRoute: hasUser ? '/dashboard' : '/onboarding',
        routes: {
          '/dashboard': (_) => const DashboardPage(),
          '/onboarding': (_) => const OnboardingPage(),
        },
      ),
    );
  }
}
