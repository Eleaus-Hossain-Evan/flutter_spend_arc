import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/transaction/presentation/pages/transaction_list_page.dart';
import 'hive/hive_adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());

  await initDependencies();

  runApp(const SpendArcApp());
}

class SpendArcApp extends StatelessWidget {
  const SpendArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendArc',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/transactions': (context) => const TransactionListPage(),
      },
      home: const DashboardPage(),
    );
  }
}
