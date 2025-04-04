import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;

  FirebaseStorageService._internal();
  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get user avatar reference
  Reference _getUserAvatarRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    return _storage.ref().child('user_avatars').child('${user.uid}_avatar.jpg');
  }
  
  // Upload avatar to Firebase Storage
  Future<String> uploadAvatar(File file) async {
    try {
      final ref = _getUserAvatarRef();
      
      // Upload file with content type
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Avatar uploaded to Firebase Storage: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading avatar to Firebase Storage: $e');
      rethrow;
    }
  }
  
  // Download avatar from Firebase Storage
  Future<File?> downloadAvatar(String localPath) async {
    try {
      final ref = _getUserAvatarRef();
      final file = File(localPath);
      
      // Create directory if it doesn't exist
      final dir = path.dirname(localPath);
      await Directory(dir).create(recursive: true);
      
      // Download to file
      await ref.writeToFile(file);
      print('Avatar downloaded to: $localPath');
      
      return file;
    } catch (e) {
      print('Error downloading avatar from Firebase Storage: $e');
      // Return null if file doesn't exist or other error
      return null;
    }
  }
  
  // Check if avatar exists in Firebase Storage
  Future<bool> avatarExists() async {
    try {
      final ref = _getUserAvatarRef();
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Delete avatar from Firebase Storage
  Future<void> deleteAvatar() async {
    try {
      final ref = _getUserAvatarRef();
      await ref.delete();
      print('Avatar deleted from Firebase Storage');
    } catch (e) {
      print('Error deleting avatar from Firebase Storage: $e');
      // Ignore if file doesn't exist
    }
  }
}
