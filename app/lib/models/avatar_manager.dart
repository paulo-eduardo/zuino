import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mercadinho/services/firebase_storage_service.dart';
import 'package:path/path.dart' as path;

class AvatarManager extends ChangeNotifier {
  static final AvatarManager _instance = AvatarManager._internal();
  factory AvatarManager() => _instance;

  AvatarManager._internal() {
    // Clean up on initialization
    _cleanupOldAvatars();
  }

  File? _avatarFile;
  File? get avatarFile => _avatarFile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get avatarPath => _avatarFile?.path ?? '';
  String get timestamp => _avatarFile?.path ?? DateTime.now().toIso8601String();
  
  final FirebaseStorageService _storageService = FirebaseStorageService();

  Future<String> _getAvatarDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/avatars';
  }

  Future<void> _cleanupOldAvatars() async {
    final avatarDir = Directory(await _getAvatarDirectory());

    if (await avatarDir.exists()) {
      final files = await avatarDir.list().toList();

      // Keep only current_avatar.jpg, delete others
      for (var entity in files) {
        final file = File(entity.path);
        if (path.basename(file.path) != 'current_avatar.jpg') {
          try {
            await file.delete();
          } catch (e) {
            print('Error deleting old avatar file: $e');
          }
        }
      }
    }
  }

  Future<void> loadAvatar() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final avatarDir = Directory(await _getAvatarDirectory());
      final avatarPath = '${await _getAvatarDirectory()}/current_avatar.jpg';

      // Step 1: Check if avatar exists locally
      if (await avatarDir.exists()) {
        final files = await avatarDir.list().toList();
        if (files.isNotEmpty) {
          // Find current_avatar.jpg if it exists
          for (var entity in files) {
            if (path.basename(entity.path) == 'current_avatar.jpg') {
              _avatarFile = File(entity.path);
              _isLoading = false;
              notifyListeners();
              return;
            }
          }
        }
      }
      
      // Step 2: If not found locally, try to download from Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && await _storageService.avatarExists()) {
        _avatarFile = await _storageService.downloadAvatar(avatarPath);
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Step 3: If not found in Firebase either, avatar remains null (default will be used)
      _avatarFile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading avatar: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(File newFile) async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final avatarDir = Directory(await _getAvatarDirectory());

      // Create avatars directory if it doesn't exist
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // Use consistent filename for local storage
      final newPath = '${avatarDir.path}/current_avatar.jpg';

      // Copy new file
      _avatarFile = await newFile.copy(newPath);

      // Clean up old avatar files
      await _cleanupOldAvatars();

      // Upload to Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _storageService.uploadAvatar(_avatarFile!);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error updating avatar: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAvatar() async {
    if (_isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final avatarDir = Directory(await _getAvatarDirectory());

      if (await avatarDir.exists()) {
        try {
          await avatarDir.delete(recursive: true);
        } catch (e) {
          print('Error deleting local avatar directory: $e');
        }
      }

      // Also delete from Firebase Storage
      try {
        await _storageService.deleteAvatar();
      } catch (e) {
        print('Error deleting avatar from Firebase Storage: $e');
      }

      _avatarFile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error clearing avatar: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  // Call this method when user logs out
  Future<void> handleLogout() async {
    await clearAvatar();
  }
}
