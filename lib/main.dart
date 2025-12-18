import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/theme_provider.dart';
import 'services/sqlite_service.dart';
import 'services/firebase_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= DATES =================
  await initializeDateFormatting('fr_FR');

  // ================= TIMEZONE =================
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));

  

  // ================= FIREBASE =================
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAQVXSE332VhsX7AHVEiHnXRc1MstY9CAo",
      appId: "1:908087767884:android:5908ae8354471b2da1d5e9",
      messagingSenderId: "908087767884",
      projectId: "calorie-app-7232c",
      storageBucket: "calorie-app-7232c.firebasestorage.app",
    ),
  );
  // ================= FCM =================
  final fcmService = FCMService();
  await fcmService.initialize();
  // ================= SERVICES =================
  final sqliteService = await SQLiteService.instance.init();
  final firebaseService = FirebaseService();

  // ================= APP =================
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(firebaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => CalorieProvider(sqliteService, firebaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
