import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/components/base_item_card.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/models/shopping_item.dart';

class ProductCard extends StatelessWidget {
  final String code;
  final String name;
  final String? category;
  final Function? onProductAdded;
  final bool isEditMode;
  final Function? onEditPressed;
  final _logger = Logger('ProductCard');
  final _shoppingListDb = ShoppingListDatabase();

  ProductCard({
    super.key,
    required this.code,
    required this.name,
    this.category,
    this.onProductAdded,
    this.isEditMode = false,
    this.onEditPressed,
  });

  Future<void> _addToShoppingList() async {
    try {
      _logger.info('Attempting to add product to shopping list: $code');

      // Check if item already exists in shopping list
      final existingItem = await _shoppingListDb.getItem(code);

      if (existingItem != null) {
        // If item exists, increment quantity
        _logger.info(
          'Product already in shopping list, increasing quantity: $code',
        );
        await _shoppingListDb.updateQuantity(code, existingItem.quantity + 1);
        _logger.info('Increased quantity for item: $code');
      } else {
        // If item doesn't exist, add it with quantity 1
        _logger.info('Adding new product to shopping list: $code');
        final newItem = ShoppingItem(productCode: code);
        await _shoppingListDb.addOrUpdateItem(newItem);
        _logger.info('Added new item to shopping list: $code');
      }

      // Call the callback to notify parent components
      if (onProductAdded != null) {
        onProductAdded!();
      }
    } catch (e) {
      _logger.error('Error adding product to shopping list', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseItemCard(
      name: name,
      category: category,
      isEditMode: isEditMode,
      onTap: () {
        if (isEditMode && onEditPressed != null) {
          onEditPressed!();
        } else if (!isEditMode) {
          _addToShoppingList();

          // Show a snackbar to confirm the item was added
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name adicionado à lista de compras'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Ver Lista',
                onPressed: () {
                  // Navigate to shopping list screen
                  Navigator.pushNamed(context, '/shopping_list');
                },
              ),
            ),
          );
        }
      },
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
