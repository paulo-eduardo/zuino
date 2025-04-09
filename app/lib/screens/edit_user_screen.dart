import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:zuino/models/avatar_manager.dart';
import 'package:zuino/components/avatar_preview.dart';
import 'package:zuino/models/app_user_info.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;
  final _avatarManager = AvatarManager();

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _nameController.text = _user.displayName ?? '';
      _avatarManager.addListener(_onAvatarChanged);
      // Load avatar after the widget is fully built
      Future.microtask(() => _avatarManager.loadAvatar());
    }
  }

  @override
  void dispose() {
    _avatarManager.removeListener(_onAvatarChanged);
    super.dispose();
  }

  void _onAvatarChanged() {
    setState(() {});
  }

  Future<void> _updateAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final selectedFile = File(image.path);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => AvatarPreview(
                imageFile: selectedFile,
                onSave: (croppedFile) async {
                  await _avatarManager.updateAvatar(croppedFile);
                },
              ),
        ),
      );

      if (!mounted) return;

      // Force refresh the avatar display
      setState(() {});
    }
  }

  Future<void> _updateDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Por favor, insira um nome válido.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Update Firebase Auth display name
      await _user?.updateDisplayName(newName);
      await _user?.reload();

      // Update local cache
      final updatedUser = FirebaseAuth.instance.currentUser;
      AppUserInfo.updateFromFirebaseUser(updatedUser);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      Fluttertoast.showToast(
        msg: 'Nome atualizado com sucesso!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      // Navigate back to home screen with result
      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful update
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      Fluttertoast.showToast(
        msg: 'Erro ao atualizar o nome: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250, // Avatar size
                  height: 250, // Avatar size
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 3,
                    ), // Thicker border
                  ),
                  child: ClipOval(
                    child:
                        _avatarManager.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _avatarManager.avatarImageBytes != null
                            ? Image.memory(
                              _avatarManager.avatarImageBytes!,
                              fit: BoxFit.cover,
                              key: ValueKey(_avatarManager.version),
                              gaplessPlayback: false,
                            )
                            : Image.asset(
                              'assets/default_avatar.png',
                              fit: BoxFit.cover,
                            ),
                  ),
                ),
                Positioned(
                  bottom: 10, // Position the button at the bottom-right corner
                  right: 10,
                  child: FloatingActionButton(
                    onPressed: _updateAvatar,
                    mini: true, // Smaller button
                    backgroundColor: Colors.blue,
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ), // Pencil icon
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Nome de Exibição:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite o novo nome de exibição',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateDisplayName,
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
