import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:mercadinho/screens/stock_screen.dart'; // Ensure correct StockScreen import
import 'package:mercadinho/models/app_user_info.dart'; // Update import

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Explicitly specify the file name
  } catch (e) {}
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  await Firebase.initializeApp();
  FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  ); // Enable verbose logging
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    AppUserInfo.updateFromFirebaseUser(user); // Update global user info
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2C2C2C), // Neutral dark tone
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(
            0xFF2C2C2C,
          ), // Same neutral dark tone for the header
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
      home: StockScreen(
        title: "Estoque de ${AppUserInfo.name}",
      ), // Use global user info
    );
  }
}
