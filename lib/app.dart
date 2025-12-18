import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projet/screens/login_screen.dart';
import 'package:projet/screens/home_screen.dart';
import 'package:projet/screens/add_entry_screen.dart';
import 'package:projet/screens/stats_screen.dart';
import 'package:projet/providers/auth_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calorie App',
      theme: theme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/add': (context) => const AddEntryScreen(),
        '/stats': (context) => const StatsScreen(),
      },
    );
  }
}