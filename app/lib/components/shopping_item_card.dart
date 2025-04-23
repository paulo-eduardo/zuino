import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/screens/edit_product_screen.dart';
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
  bool _showQuantityControls = false;
  ValueListenable<Box<dynamic>>? _productListenable;

  @override
  void initState() {
    super.initState();
    _initializeProductListener();
  }

  Future<void> _initializeProductListener() async {
    try {
      // Initial load of product details
      await _loadProductDetails();

      // Set up the listenable for product changes
      final listenable = await _productDb.getListenable();

      if (mounted) {
        setState(() {
          _productListenable = listenable;
        });

        // Add listener to reload product details when the product database changes
        _productListenable!.addListener(_handleProductChanges);
      }
    } catch (e) {
      _logger.error('Error initializing product listener', e);
    }
  }

  void _handleProductChanges() {
    // Check if the specific product we're displaying has changed
    final box = (_productListenable as ValueListenable<Box>).value;
    if (box.containsKey(widget.item.productCode)) {
      // Reload the product details
      _loadProductDetails();
    }
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

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    if (_productListenable != null) {
      _productListenable!.removeListener(_handleProductChanges);
    }
    super.dispose();
  }

  Future<void> _navigateToEditScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditProductScreen(codigo: widget.item.productCode),
      ),
    );

    // If the product was updated, reload the details
    if (result == true) {
      _loadProductDetails();
    }
  }

  void _toggleQuantityControls() {
    setState(() {
      _showQuantityControls = !_showQuantityControls;
    });
  }

  Future<void> _increaseQuantity() async {
    try {
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

    // Custom overlay to show quantity and controls
    Widget quantityOverlay = Positioned(
      right: 0,
      top: 0,
      child:
          _showQuantityControls
              ? _buildQuantityControls()
              : _buildQuantityBadge(),
    );

    return GestureDetector(
      onTap: _toggleQuantityControls,
      onLongPress: () => _navigateToEditScreen(context),
      child: BaseItemCard(
        name: name,
        category: category,
        isLoading: _isLoading,
        overlay: quantityOverlay,
        onTap: null, // We're handling tap in the GestureDetector
        fixedSize: true,
        roundTopLeft: widget.roundTopLeft,
        roundTopRight: widget.roundTopRight,
        roundBottomLeft: widget.roundBottomLeft,
        roundBottomRight: widget.roundBottomRight,
      ),
    );
  }

  Widget _buildQuantityBadge() {
    return ClipRRect(
      // Only round the top-right corner if the card has a rounded top-right corner
      borderRadius: BorderRadius.only(
        topRight: widget.roundTopRight ? const Radius.circular(8) : Radius.zero,
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
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(230),
        borderRadius: BorderRadius.only(
          topRight:
              widget.roundTopRight ? const Radius.circular(8) : Radius.zero,
          bottomLeft: const Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Minus button
          InkWell(
            onTap: _decreaseQuantity,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 18),
            ),
          ),

          // Quantity display
          Text(
            '${widget.item.quantity}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Plus button
          InkWell(
            onTap: _increaseQuantity,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
