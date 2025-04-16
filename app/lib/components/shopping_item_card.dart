import 'package:flutter/material.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/utils/logger.dart';
import 'base_item_card.dart';

class ShoppingItemCard extends StatefulWidget {
  final ShoppingItem item;

  const ShoppingItemCard({super.key, required this.item});

  @override
  State<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends State<ShoppingItemCard> {
  final _logger = Logger('ShoppingItemCard');
  final _productDb = ProductDatabase();
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

  @override
  Widget build(BuildContext context) {
    final name = _productDetails?.name;
    final category = _productDetails?.category;

    // Custom overlay to show quantity
    Widget quantityOverlay = Positioned(
      right: 4,
      top: 0, // Changed from 4 to -4 to float it higher
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ), // Added white border for better visibility
        ),
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        alignment: Alignment.center,
        child: Text(
          '${widget.item.quantity}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return BaseItemCard(
      name: name,
      category: category,
      isLoading: _isLoading,
      overlay: quantityOverlay,
      onTap: () {
        // Handle tap if needed
      },
    );
  }
}
