import 'package:flutter/material.dart';
import 'package:zuino/components/user_avatar.dart';
import 'package:zuino/models/app_user_info.dart';

class PageHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showAvatar;
  final Widget? actionButton;
  final VoidCallback? onAvatarChanged;

  const PageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showAvatar = true,
    this.actionButton,
    this.onAvatarChanged,
  }) : super(key: key);

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  @override
  Widget build(BuildContext context) {
    // Get user's first name safely if title is "greeting"
    String displayTitle = widget.title;
    if (displayTitle == "greeting") {
      final userName = AppUserInfo.name ?? "Usuário";
      final firstName = userName.split(' ')[0];
      displayTitle = 'Olá, $firstName';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button if needed
          if (widget.showBackButton && Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

          // Title and subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: widget.showBackButton ? 8.0 : 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[400]),
                    ),
                  ],
                ],
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
