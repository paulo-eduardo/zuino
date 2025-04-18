import 'package:flutter/material.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/utils/logger.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'base_item_card.dart';

class ShoppingItemCard extends StatefulWidget {
  final ShoppingItem item;
  final Function? onQuantityChanged;
  final bool roundTopLeft;
  final bool roundTopRight;
  final bool roundBottomLeft;
  final bool roundBottomRight;

  const ShoppingItemCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.roundTopLeft = true,
    this.roundTopRight = true,
    this.roundBottomLeft = true,
    this.roundBottomRight = true,
  });

  @override
  State<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends State<ShoppingItemCard> {
  final _logger = Logger('ShoppingItemCard');
  final _productDb = ProductDatabase();
  final _shoppingListDb = ShoppingListDatabase();
  Product? _productDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final details = await _productDb.getProduct(widget.item.productCode);
      if (mounted) {
        setState(() {
          _productDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error loading product details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _increaseQuantity() async {
    try {
      _logger.info('Increasing quantity for: ${widget.item.productCode}');
      await _shoppingListDb.incrementQuantity(widget.item.productCode, 1.0);

      if (widget.onQuantityChanged != null) {
        widget.onQuantityChanged!();
      }

      Fluttertoast.showToast(
        msg: "Quantity increased",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      _logger.error('Error increasing quantity: $e');
    }
  }

  Future<void> _decreaseQuantity() async {
    try {
      _logger.info('Decreasing quantity for: ${widget.item.productCode}');

      // If quantity is 1, this will remove the item as implemented in the incrementQuantity method
      // with a negative value
      await _shoppingListDb.incrementQuantity(widget.item.productCode, -1.0);

      if (widget.onQuantityChanged != null) {
        widget.onQuantityChanged!();
      }

      if (widget.item.quantity > 1) {
        Fluttertoast.showToast(
          msg: "Quantity decreased",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Item removed from shopping list",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      _logger.error('Error decreasing quantity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _productDetails?.name;
    final category = _productDetails?.category;

    // Custom overlay to show quantity
    Widget quantityOverlay = Positioned(
      right: 0,
      top: 0,
      child: ClipRRect(
        // Only round the top-right corner if the card has a rounded top-right corner
        borderRadius: BorderRadius.only(
          topRight:
              widget.roundTopRight ? const Radius.circular(8) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6), // Smaller padding
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(204),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10), // Slightly smaller radius
            ),
          ),
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ), // Smaller constraints
          alignment: Alignment.center,
          child: Text(
            '${widget.item.quantity}',
            style: TextStyle(
              color: Colors.white,
              fontSize:
                  widget.item.quantity >= 10
                      ? 12
                      : 14, // Smaller font for double digits
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onLongPress: _decreaseQuantity,
      child: BaseItemCard(
        name: name,
        category: category,
        isLoading: _isLoading,
        overlay: quantityOverlay,
        onTap: _increaseQuantity,
        fixedSize: true,
        roundTopLeft: widget.roundTopLeft,
        roundTopRight: widget.roundTopRight,
        roundBottomLeft: widget.roundBottomLeft,
        roundBottomRight: widget.roundBottomRight,
      ),
    );
  }
}
