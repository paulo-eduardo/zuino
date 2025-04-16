import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:zuino/models/app_user_info.dart'; // Update import
import 'package:zuino/screens/shopping_screen.dart';

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Explicitly specify the file name
  } catch (e) {
    // Silently continue if .env file is missing or invalid
    // This allows the app to run with default values in production
  }
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
      title: 'Zuino',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF333333),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blue[700]!,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      // Use ShoppingScreen as the home screen
      home: const ShoppingScreen(),
    );
  }
}
