import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuino/services/firebase_storage_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zuino/utils/logger.dart';

class AvatarManager extends ChangeNotifier {
  static final AvatarManager _instance = AvatarManager._internal();
  factory AvatarManager() => _instance;

  final Logger _logger = Logger('AvatarManager');

  AvatarManager._internal();

  // In-memory image data
  Uint8List? _avatarImageBytes;
  Uint8List? get avatarImageBytes => _avatarImageBytes;

  // File reference (for upload/download operations)
  File? _avatarFile;
  File? get avatarFile => _avatarFile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Simple version counter that increments with each avatar update
  int _version = 0;
  int get version => _version;

  // Flag to indicate if avatar was updated
  bool _hasNewAvatar = false;
  bool get hasNewAvatar => _hasNewAvatar;

  final FirebaseStorageService _storageService = FirebaseStorageService();

  Future<String> _getAvatarDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/avatars';
  }

  Future<void> loadAvatar() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      // Delay notification until after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final avatarDir = await _getAvatarDirectory();
      final avatarPath = '$avatarDir/user-avatar.jpg';

      // Step 1: Check if avatar exists locally
      final file = File(avatarPath);
      if (await file.exists()) {
        _avatarImageBytes = await file.readAsBytes();
        _avatarFile = file;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: If not found locally, try to download from Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // First check if avatar exists in Firebase Storage
          if (await _storageService.avatarExists()) {
            _avatarFile = await _storageService.downloadAvatar(avatarPath);
            if (_avatarFile != null && await _avatarFile!.exists()) {
              _avatarImageBytes = await _avatarFile!.readAsBytes();
              _isLoading = false;
              notifyListeners();
              return;
            } else {
              _logger.debug('Downloaded avatar file is null or does not exist');
            }
          } else {
            _logger.debug('Avatar does not exist in Firebase Storage');
          }
        } catch (e) {
          _logger.error('Error downloading avatar from Firebase', e);
        }
      }

      // Step 3: If not found in Firebase either, avatar remains null (default will be used)
      _avatarImageBytes = null;
      _avatarFile = null;
      _isLoading = false;
      // Delay notification until after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _logger.error('Error loading avatar', e);
      _isLoading = false;
      // Delay notification until after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> updateAvatar(File newFile) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Increment version counter to force UI refresh
      _version++;

      // Set flag to indicate new avatar
      _hasNewAvatar = true;

      // Read the image bytes into memory
      _avatarImageBytes = await newFile.readAsBytes();

      // Save to disk for persistence
      final avatarDir = Directory(await _getAvatarDirectory());
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // Use consistent filename for local storage
      final newPath = '${avatarDir.path}/user-avatar.jpg';

      // Write the file to disk
      _avatarFile = await File(newPath).writeAsBytes(_avatarImageBytes!);

      // Set loading to false and notify listeners before starting the upload
      _isLoading = false;
      // Delay notification until after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Upload to Firebase Storage in the background
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Don't await this - let it run in the background
        _uploadAvatarInBackground(_avatarFile!);
      }
    } catch (e) {
      _logger.error('Error updating avatar', e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAvatar() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Clear in-memory image
      _avatarImageBytes = null;

      // Increment version to force UI refresh
      _version++;

      // Reset new avatar flag
      _hasNewAvatar = false;

      final avatarDir = Directory(await _getAvatarDirectory());
      if (await avatarDir.exists()) {
        try {
          await avatarDir.delete(recursive: true);
        } catch (e) {
          _logger.error('Error deleting local avatar directory', e);
        }
      }

      _avatarFile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Error clearing avatar', e);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Show toast message
  void _showToast(String message, bool isSuccess) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Upload avatar in the background
  Future<void> _uploadAvatarInBackground(File file) async {
    try {
      await _storageService.uploadAvatar(file);
      _logger.info('Avatar uploaded to Firebase Storage successfully');
      _showToast('Avatar uploaded successfully', true);
    } catch (e) {
      _logger.error('Error uploading avatar to Firebase Storage', e);
      _showToast('Failed to upload avatar', false);
      // The avatar is already saved locally, so the user can still use it
    }
  }

  // Call this method when user logs out
  Future<void> handleLogout() async {
    // Only clear the avatar locally, not from Firebase Storage
    try {
      _isLoading = true;
      notifyListeners();

      // Clear in-memory image
      _avatarImageBytes = null;

      // Increment version to force UI refresh
      _version++;

      // Reset new avatar flag
      _hasNewAvatar = false;

      final avatarDir = Directory(await _getAvatarDirectory());
      if (await avatarDir.exists()) {
        try {
          await avatarDir.delete(recursive: true);
        } catch (e) {
          _logger.error('Error deleting local avatar directory', e);
        }
      }

      _avatarFile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Error handling logout', e);
      _isLoading = false;
      notifyListeners();
    }
  }
}
