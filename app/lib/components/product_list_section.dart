import 'package:flutter/material.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/screens/edit_product_screen.dart';
import 'package:zuino/utils/logger.dart';

class ProductListSection extends StatefulWidget {
  final String title;
  final VoidCallback? onListUpdated;

  const ProductListSection({
    super.key,
    required this.title,
    this.onListUpdated,
  });

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends State<ProductListSection> {
  final _logger = Logger('ProductListSection');
  final _productDb = ProductDatabase();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final products = await _productDb.getAllProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error loading products', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _navigateToEditScreen(Product product) {
    // Exit edit mode
    setState(() {
      _isEditMode = false;
    });

    // Navigate to edit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditProductScreen(
              codigo: product.code,
              onProductUpdated: () {
                // Reload products when returning from edit screen
                _loadProducts();
                if (widget.onListUpdated != null) {
                  widget.onListUpdated!();
                }
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with edit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Edit/Cancel button
              IconButton(
                icon: Icon(
                  _isEditMode ? Icons.close : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: _toggleEditMode,
              ),
            ],
          ),
        ),

        // Loading indicator, empty state, or product grid
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum produto cadastrado',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0, // Perfect square
                  crossAxisSpacing: 0.0,
                  mainAxisSpacing: 0.0,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];

                  return ShakeWidget(
                    isShaking: _isEditMode,
                    shakeOffset: 1.5, // Subtle shake
                    duration: const Duration(milliseconds: 700),
                    child: GestureDetector(
                      onTap:
                          _isEditMode
                              ? () => _navigateToEditScreen(product)
                              : null,
                      child: ProductCard(
                        name: product.name,
                        code: product.code,
                        category: product.category,
                        isEditMode: _isEditMode,
                        onEditPressed:
                            _isEditMode
                                ? () => _navigateToEditScreen(product)
                                : null,
                        onProductAdded: widget.onListUpdated,
                      ),
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }
}
