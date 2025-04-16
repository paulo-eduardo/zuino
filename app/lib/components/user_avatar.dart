import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuino/models/avatar_manager.dart';
import 'package:zuino/screens/edit_user_screen.dart';
import 'package:zuino/screens/login_screen.dart';
import 'package:zuino/utils/logger.dart';

class UserAvatar extends StatefulWidget {
  final double radius;
  final bool showMenu;
  final VoidCallback? onAvatarChanged;

  const UserAvatar({
    super.key,
    this.radius = 24.0,
    this.showMenu = true,
    this.onAvatarChanged,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  final _logger = Logger('UserAvatar');
  final _avatarManager = AvatarManager();
  final _auth = FirebaseAuth.instance;
  bool _isAvatarLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load avatar asynchronously
    _loadAvatarAsync();
  }

  // Load avatar in the background without blocking UI
  Future<void> _loadAvatarAsync() async {
    try {
      await _avatarManager.loadAvatar();
      if (mounted) {
        setState(() {
          _isAvatarLoaded = true;
        });
      }
    } catch (e) {
      _logger.error('Error loading avatar', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.showMenu ? _showAvatarMenu : _editProfile,
      child: Hero(tag: 'userAvatar', child: _buildAvatarImage()),
    );
  }

  Widget _buildAvatarImage() {
    // First check if avatar is loaded and we have avatar bytes in memory
    if (_isAvatarLoaded && _avatarManager.avatarImageBytes != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[800],
        backgroundImage: MemoryImage(_avatarManager.avatarImageBytes!),
      );
    }

    // Then check if avatar is loaded and we have a local avatar file
    if (_isAvatarLoaded &&
        _avatarManager.avatarFile != null &&
        _avatarManager.avatarFile!.existsSync()) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[800],
        backgroundImage: FileImage(_avatarManager.avatarFile!),
      );
    }

    // Default: Use default avatar image while loading or if no avatar is available
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey[800],
      backgroundImage: const AssetImage('assets/default_avatar.png'),
      child: _isAvatarLoaded ? null : _buildLoadingIndicator(),
    );
  }

  Widget? _buildLoadingIndicator() {
    // Only show loading indicator if we're still loading
    // and not on very small avatars
    if (widget.radius < 20) return null;

    return SizedBox(
      width: widget.radius,
      height: widget.radius,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showAvatarMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Calculate position to show menu below the avatar
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    // Create a position that places the menu below the avatar with a small offset
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx, // Left
      buttonPosition.dy +
          buttonSize.height +
          4, // Top (below avatar with 4px gap)
      buttonPosition.dx + buttonSize.width, // Right
      0.0, // Bottom
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Editar Perfil'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _editProfile();
      } else if (value == 'logout') {
        _logout();
      }
    });
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditUserScreen()),
    ).then((_) {
      // Refresh avatar when returning from profile edit
      _loadAvatarAsync();
      if (widget.onAvatarChanged != null) {
        widget.onAvatarChanged!();
      }
    });
  }

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Sair'),
              content: const Text('Tem certeza que deseja sair?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Sair',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Handle avatar cleanup
      await _avatarManager.handleLogout();

      // Sign out from Firebase
      await _auth.signOut();

      if (!mounted) return;

      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _logger.error('Error during logout', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: ${e.toString()}')),
        );
      }
    }
  }
}
