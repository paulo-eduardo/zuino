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
    
    // Use consistent naming format for avatar files
    return _storage.ref().child('user_avatars').child('${user.uid}_avatar.jpg');
  }
  
  // Get user avatar reference with legacy format (if needed)
  Reference _getLegacyUserAvatarRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Legacy format that might have been used previously
    return _storage.ref().child('user_avatars').child(user.uid);
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
    // Create file and directory
    final file = File(localPath);
    final dir = path.dirname(localPath);
    await Directory(dir).create(recursive: true);
    
    // Try current format first
    try {
      final ref = _getUserAvatarRef();
      
      // Get download URL first to verify the file exists
      final downloadUrl = await ref.getDownloadURL();
      print('Avatar download URL (current format): $downloadUrl');
      
      // Download to file
      await ref.writeToFile(file);
      print('Avatar downloaded to: $localPath');
      
      // Verify file was created
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Downloaded avatar file size: $fileSize bytes');
        if (fileSize > 0) {
          return file;
        }
      }
    } catch (e) {
      print('Error downloading avatar with current format: $e');
      
      // Try legacy format as fallback
      try {
        final legacyRef = _getLegacyUserAvatarRef();
        
        // Get download URL to verify the file exists
        final downloadUrl = await legacyRef.getDownloadURL();
        print('Avatar download URL (legacy format): $downloadUrl');
        
        // Download to file
        await legacyRef.writeToFile(file);
        print('Avatar downloaded from legacy format to: $localPath');
        
        // Verify file was created
        if (await file.exists()) {
          final fileSize = await file.length();
          print('Downloaded avatar file size: $fileSize bytes');
          if (fileSize > 0) {
            // Also upload to the new format for future consistency
            try {
              await uploadAvatar(file);
              print('Migrated avatar from legacy to current format');
            } catch (e) {
              print('Failed to migrate avatar format: $e');
            }
            return file;
          }
        }
      } catch (e) {
        print('Error downloading avatar with legacy format: $e');
      }
    }
    
    print('Failed to download avatar in any format');
    return null;
  }
  
  // Check if avatar exists in Firebase Storage
  Future<bool> avatarExists() async {
    try {
      // Try the current format first
      final ref = _getUserAvatarRef();
      await ref.getDownloadURL();
      print('Avatar exists in Firebase Storage with current format');
      return true;
    } catch (e) {
      print('Avatar not found with current format, trying legacy format...');
      
      // Try the legacy format as fallback
      try {
        final legacyRef = _getLegacyUserAvatarRef();
        await legacyRef.getDownloadURL();
        print('Avatar exists in Firebase Storage with legacy format');
        return true;
      } catch (e) {
        print('Avatar does not exist in Firebase Storage in any format: $e');
        return false;
      }
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
