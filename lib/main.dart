// lib/main.dart

// The entry point of every Flutter application
// This file sets up the app, initializes dependencies, and starts the widget tree

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/transaction_model.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

// main() is the program entry point (same as in every Dart/Java/C++ program)
// async because we need to await Hive initialization before starting the app
void main() async {
  // WidgetsFlutterBinding.ensureInitialized() must be called before any
  // async operations that use platform channels (like Hive file access)
  // It sets up the connection between Flutter's widget layer and the OS
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with Flutter-specific path resolution
  // This creates/finds the app's storage directory (different per OS)
  await Hive.initFlutter();

  // Register the TypeAdapter BEFORE opening any boxes that use this type
  // The adapter tells Hive how to serialize/deserialize TransactionModel
  Hive.registerAdapter(TransactionModelAdapter());

  // runApp() takes the root widget and starts the Flutter app
  // Everything in Flutter is a Widget - even the app itself
  runApp(const MyApp());
}

// MyApp is a StatelessWidget because the root app config never changes
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider allows injecting multiple providers at once
    // All providers become available to the entire widget tree below
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider creates TransactionProvider ONCE
        // and makes it available to all descendant widgets
        ChangeNotifierProvider(
          // create is a factory function called once to instantiate the provider
          create: (_) => TransactionProvider()..init(),
          // ..init() uses the cascade operator:
          // creates TransactionProvider(), calls .init() on it, returns it
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false, // Remove debug banner

        // Apply our custom dark theme
        theme: AppTheme.darkTheme,

        // The first screen shown when the app launches
        home: const HomeScreen(),
      ),
    );
  }
}