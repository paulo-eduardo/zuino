import 'package:flutter/material.dart';
import 'package:zuino/components/user_avatar.dart';
import 'package:zuino/models/app_user_info.dart';

class PageHeader extends StatefulWidget {
  final bool showBackButton;
  final bool showAvatar;
  final Widget? actionButton;
  final VoidCallback? onAvatarChanged;
  final String? title;

  const PageHeader({
    super.key,
    this.showBackButton = false,
    this.showAvatar = true,
    this.actionButton,
    this.onAvatarChanged,
    this.title,
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  @override
  Widget build(BuildContext context) {
    final userName = AppUserInfo.name ?? "Usuário";
    final firstName = userName.split(' ')[0];
    String displayTitle = widget.title ?? 'Olá, $firstName';

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button if needed
          if (widget.showBackButton && Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

          // Title
          Expanded(
            child: Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Action button (if provided)
          if (widget.actionButton != null) widget.actionButton!,

          // User avatar (if enabled)
          if (widget.showAvatar) ...[
            const SizedBox(width: 8.0),
            UserAvatar(onAvatarChanged: widget.onAvatarChanged),
          ],
        ],
      ),
    );
  }
}
