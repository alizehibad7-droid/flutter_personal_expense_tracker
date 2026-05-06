import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction_model.dart';
import 'models/custom_category_model.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  // Required when using async in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (finds/creates storage folder on phone)
  await Hive.initFlutter();

  // Register adapters so Hive knows how to store our objects
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(CustomCategoryModelAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          // create provider + call init() using cascade (..) operator
          create: (_) => TransactionProvider()..init(),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}