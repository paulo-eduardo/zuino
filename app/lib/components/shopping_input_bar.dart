import 'package:flutter/material.dart';

class ShoppingInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final VoidCallback onMenuPressed;
  final FocusNode? focusNode;
  final GlobalKey? menuButtonKey;
  final String hintText;

  const ShoppingInputBar({
    Key? key,
    required this.controller,
    required this.onTap,
    required this.onMenuPressed,
    this.focusNode,
    this.menuButtonKey,
    this.hintText = "Eu quero comprar...",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search input field
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8.0),
                        Text(
                          hintText,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Menu button (now on the right)
              IconButton(
                key: menuButtonKey,
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: onMenuPressed,
                tooltip: 'Menu options',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
