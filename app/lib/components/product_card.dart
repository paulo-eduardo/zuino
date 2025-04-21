import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/utils/toast_manager.dart'; // Add this import
import 'package:zuino/components/base_item_card.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/screens/edit_product_screen.dart';

class ProductCard extends StatelessWidget {
  final String code;
  final String name;
  final String? category;
  final bool isEditMode;
  final bool roundTopLeft;
  final bool roundTopRight;
  final bool roundBottomLeft;
  final bool roundBottomRight;
  final _logger = Logger('ProductCard');
  final _shoppingListDb = ShoppingListDatabase();

  ProductCard({
    super.key,
    required this.code,
    required this.name,
    this.category,
    this.isEditMode = false,
    this.roundTopLeft = true,
    this.roundTopRight = true,
    this.roundBottomLeft = true,
    this.roundBottomRight = true,
  });

  Future<void> _addToShoppingList() async {
    try {
      // Check if the item already exists in the shopping list
      final exists = await _shoppingListDb.itemExists(code);

      if (exists) {
        // If it exists, increment the quantity
        await _shoppingListDb.incrementQuantity(code, 1.0);
      } else {
        // If it doesn't exist, add it with quantity 1
        final item = ShoppingItem(productCode: code, quantity: 1.0);
        await _shoppingListDb.addOrUpdateItem(item);
      }
    } catch (e) {
      _logger.error('Error adding product to shopping list: $e');
      ToastManager.showError("Error adding to shopping list");
    }
  }

  Future<void> _navigateToEditScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditProductScreen(codigo: code, onProductUpdated: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Edit button overlay for edit mode
    Widget? overlay;
    if (isEditMode) {
      overlay = Positioned(
        right: 0,
        top: 0,
        child: ClipRRect(
          // Only round the top-right corner if the card has a rounded top-right corner
          borderRadius: BorderRadius.only(
            topRight: roundTopRight ? const Radius.circular(8) : Radius.zero,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToEditScreen(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(204),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap:
          isEditMode
              ? () => _navigateToEditScreen(context)
              : _addToShoppingList,
      child: BaseItemCard(
        name: name,
        category: category,
        isEditMode: false, // We're handling our own edit overlay
        overlay: overlay,
        fixedSize: true,
        roundTopLeft: roundTopLeft,
        roundTopRight: roundTopRight,
        roundBottomLeft: roundBottomLeft,
        roundBottomRight: roundBottomRight,
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
