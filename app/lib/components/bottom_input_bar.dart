import 'package:flutter/material.dart';

class BottomInputBar extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Callback when the menu button is pressed
  final VoidCallback onMenuPressed;

  /// Optional hint text for the text field
  final String? hintText;

  /// Optional focus node for the text field
  final FocusNode? focusNode;

  const BottomInputBar({
    super.key,
    required this.controller,
    required this.onMenuPressed,
    this.hintText = "Buscar ou adicionar item...",
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Menu button
          Container(
            margin: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.blue, size: 28),
              onPressed: onMenuPressed,
              tooltip: "Menu de opções",
            ),
          ),
        ],
      ),
    );
  }
}
