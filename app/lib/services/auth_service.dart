import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuino/models/avatar_manager.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AvatarManager _avatarManager = AvatarManager();

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    try {
      // Clear avatar from local storage and Firebase Storage
      await _avatarManager.handleLogout();

      // Sign out from Firebase Auth
      await _auth.signOut();

      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
