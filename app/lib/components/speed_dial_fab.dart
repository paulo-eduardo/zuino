import 'package:flutter/material.dart';

class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialItem> items;
  final IconData mainIcon;
  final Color mainIconColor;
  final Color backgroundColor;

  const SpeedDialFab({
    Key? key,
    required this.items,
    this.mainIcon = Icons.add,
    this.mainIconColor = Colors.white,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Show speed dial items when open
        if (_isOpen) ...[..._buildSpeedDialItems(), const SizedBox(height: 16)],

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animation,
            color: widget.mainIconColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSpeedDialItems() {
    return widget.items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            if (item.label != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.label!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            // Mini FAB
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: () {
                  _toggle(); // Close the speed dial
                  item.onTap();
                },
                backgroundColor: item.backgroundColor,
                mini: true,
                child: Icon(item.icon, color: item.iconColor),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class SpeedDialItem {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color backgroundColor;
  final Color iconColor;

  SpeedDialItem({
    required this.icon,
    required this.onTap,
    this.label,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
  });
}
