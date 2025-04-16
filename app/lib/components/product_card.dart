import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zuino/utils/logger.dart';

class ProductCard extends StatelessWidget {
  final String code;
  final String name;
  final String? category;
  final Function? onProductAdded;
  final bool isEditMode;
  final Function? onEditPressed;

  ProductCard({
    super.key,
    required this.code,
    required this.name,
    this.category,
    this.onProductAdded,
    this.isEditMode = false,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get the theme colors
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on theme and edit mode
    final cardColor =
        isDarkMode
            ? (isEditMode ? Colors.grey[800] : Colors.grey[850])
            : (isEditMode ? Colors.blue[50] : Colors.white);

    final iconColor = isDarkMode ? Colors.blue[300] : Colors.blue[700];
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side:
            isEditMode
                ? BorderSide(color: Colors.blue[400]!, width: 1.0)
                : BorderSide.none,
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Expanded(
              flex: 3,
              child: Icon(Icons.inventory_2, size: 36.0, color: iconColor),
            ),

            // Product name
            Expanded(
              flex: 1,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add a ShakeWidget to create the shake animation
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool isShaking;
  final double shakeOffset;
  final Duration duration;

  const ShakeWidget({
    Key? key,
    required this.child,
    this.isShaking = false,
    this.shakeOffset = 2.0,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _horizontalOffsetAnimation;
  late Animation<double> _verticalOffsetAnimation;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    // Initialize animations
    _updateAnimations();

    if (widget.isShaking) {
      _startRandomizedShaking();
    }
  }

  void _updateAnimations() {
    // Create horizontal animation with random offset
    _horizontalOffsetAnimation = Tween<double>(
      begin: -widget.shakeOffset * (0.5 + _random.nextDouble()),
      end: widget.shakeOffset * (0.5 + _random.nextDouble()),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Create vertical animation with smaller random offset (1/3 of horizontal)
    _verticalOffsetAnimation = Tween<double>(
      begin: -widget.shakeOffset * 0.3 * _random.nextDouble(),
      end: widget.shakeOffset * 0.3 * _random.nextDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _startRandomizedShaking() {
    _controller.forward().then((_) {
      if (widget.isShaking && mounted) {
        // Update animations with new random values
        _updateAnimations();
        // Add a tiny random delay to make it less predictable
        Future.delayed(Duration(milliseconds: (_random.nextInt(100))), () {
          if (mounted && widget.isShaking) {
            _controller.reset();
            _startRandomizedShaking();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking && !_controller.isAnimating) {
      _startRandomizedShaking();
    } else if (!widget.isShaking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isShaking) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _horizontalOffsetAnimation.value,
            _verticalOffsetAnimation.value,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
