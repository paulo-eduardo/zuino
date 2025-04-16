import 'package:flutter/material.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/utils/logger.dart';

class ShoppingItemCard extends StatefulWidget {
  final ShoppingItem item;
  final Map<String, dynamic>? productDetails;

  const ShoppingItemCard({super.key, required this.item, this.productDetails});

  @override
  State<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends State<ShoppingItemCard> {
  final _logger = Logger('ShoppingItemCard');
  final _productDb = ProductDatabase();
  Map<String, dynamic>? _productDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    if (widget.productDetails != null) {
      setState(() {
        _productDetails = widget.productDetails;
        _isLoading = false;
      });
      return;
    }

    try {
      final product = await _productDb.getProduct(widget.item.productCode);

      if (product != null) {
        if (mounted) {
          setState(() {
            _productDetails = {
              'name': product.name,
              'category': product.category,
            };
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.all(6.0),
        color: const Color(0xFF2C2C2C),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Get product details if available
    final String productName = _productDetails?['name'] ?? 'Item desconhecido';
    final String? productCategory = _productDetails?['category'];

    return Card(
      margin: const EdgeInsets.all(6.0),
      color: const Color(0xFF333333), // Dark gray background
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            const Icon(Icons.shopping_basket, color: Colors.white, size: 28.0),
            const SizedBox(height: 8.0),

            // Product name
            Text(
              productName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Category (if available)
            if (productCategory != null && productCategory.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                productCategory,
                style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                textAlign: TextAlign.center,
              ),
            ],

            // Quantity information
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Qtd: ${widget.item.quantity.toStringAsFixed(widget.item.quantity.truncateToDouble() == widget.item.quantity ? 0 : 1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
