import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mercadinho/components/qr_code_reader.dart';
import 'package:mercadinho/components/product_card.dart'; // Update import
import 'package:mercadinho/database/receipts_database.dart';
import 'package:mercadinho/database/products_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mercadinho/screens/product_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:mercadinho/screens/login_screen.dart'; // Import the new login screen
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:mercadinho/screens/stock_screen.dart'; // Ensure correct StockScreen import
import 'package:mercadinho/models/app_user_info.dart'; // Update import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Explicitly specify the file name
  } catch (e) {
    print("Error loading .env file: $e");
  }
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  await Firebase.initializeApp();
  FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true); // Enable verbose logging
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    AppUserInfo.updateFromFirebaseUser(user); // Update global user info
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2C2C2C), // Neutral dark tone
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2C), // Same neutral dark tone for the header
          elevation: 0, // Flat design
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: StockScreen(title: "Estoque de ${AppUserInfo.name}"), // Use global user info
    );
  }
}
