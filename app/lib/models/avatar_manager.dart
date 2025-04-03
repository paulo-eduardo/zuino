import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AvatarManager extends ChangeNotifier {
  static final AvatarManager _instance = AvatarManager._internal();
  factory AvatarManager() => _instance;

  AvatarManager._internal() {
    // Clean up on initialization
    _cleanupOldAvatars();
  }

  File? _avatarFile;
  File? get avatarFile => _avatarFile;

  String get avatarPath => _avatarFile?.path ?? '';
  String get timestamp => _avatarFile?.path ?? DateTime.now().toIso8601String();

  Future<String> _getAvatarDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/avatars';
  }

  Future<void> _cleanupOldAvatars() async {
    final avatarDir = Directory(await _getAvatarDirectory());

    if (await avatarDir.exists()) {
      final files = await avatarDir.list().toList();

      // Sort files by last modified time to keep the most recent
      files.sort(
        (a, b) => File(
          b.path,
        ).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()),
      );

      // Keep only the most recent file
      for (var i = 1; i < files.length; i++) {
        try {
          await files[i].delete();
        } catch (e) {}
      }

      // Update current avatar file if needed
      if (files.isNotEmpty && _avatarFile?.path != files.first.path) {
        _avatarFile = File(files.first.path);
        notifyListeners();
      }
    }
  }

  Future<void> loadAvatar() async {
    final avatarDir = Directory(await _getAvatarDirectory());

    if (await avatarDir.exists()) {
      final files = await avatarDir.list().toList();
      if (files.isNotEmpty) {
        _avatarFile = File(files.first.path);
        notifyListeners();
      }
    }
  }

  Future<void> updateAvatar(File newFile) async {
    final avatarDir = Directory(await _getAvatarDirectory());

    try {
      // Create avatars directory if it doesn't exist
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${avatarDir.path}/avatar_$timestamp.jpg';

      // Copy new file
      _avatarFile = await newFile.copy(newPath);

      // Clean up old avatar files
      await _cleanupOldAvatars();

      notifyListeners();
    } catch (e) {}
  }

  Future<void> clearAvatar() async {
    final avatarDir = Directory(await _getAvatarDirectory());

    if (await avatarDir.exists()) {
      try {
        await avatarDir.delete(recursive: true);
      } catch (e) {}
    }

    _avatarFile = null;
    notifyListeners();
  }
}
