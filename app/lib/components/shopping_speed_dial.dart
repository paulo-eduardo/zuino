import 'package:flutter/material.dart';

class ShoppingSpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  ShoppingSpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor = const Color(0xFF2A2A2A),
    this.iconColor = Colors.white,
  });
}

class ShoppingSpeedDial extends StatefulWidget {
  final List<ShoppingSpeedDialItem> items;
  final Offset anchorPosition;
  final bool isOpen;
  final Function(bool) onToggle;

  const ShoppingSpeedDial({
    Key? key,
    required this.items,
    required this.anchorPosition,
    required this.isOpen,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<ShoppingSpeedDial> createState() => _ShoppingSpeedDialState();
}

class _ShoppingSpeedDialState extends State<ShoppingSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ShoppingSpeedDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Overlay to capture taps outside the menu
            Positioned.fill(
              child: GestureDetector(
                onTap: () => widget.onToggle(false),
                child: Container(color: Colors.black54),
              ),
            ),
            // Menu items
            Positioned(
              right: 16, // Adjust based on your layout
              bottom:
                  MediaQuery.of(context).size.height -
                  widget.anchorPosition.dy +
                  10,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.bottomRight,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: _buildMenuItems(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          widget.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                onTap: () {
                  widget.onToggle(false);
                  item.onTap();
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.backgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: item.iconColor),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
