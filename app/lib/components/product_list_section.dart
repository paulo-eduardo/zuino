import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/utils/toast_manager.dart'; // Add this import

class ProductListSection extends StatefulWidget {
  const ProductListSection({super.key});

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends State<ProductListSection> {
  final _logger = Logger('ProductListSection');
  final _productDb = ProductDatabase();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  String? _errorMessage;
  ValueListenable<Box>? _productsListenable;

  @override
  void initState() {
    super.initState();
    _setupListenable();
  }

  Future<void> _setupListenable() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get the listenable from the database
      final listenable = await _productDb.getListenable();

      if (mounted) {
        // Set the listenable and load products initially
        _productsListenable = listenable;
        await _loadProducts();
      }
    } catch (e, stackTrace) {
      _logger.error('Error setting up products listenable', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Erro ao configurar atualização de produtos: ${e.toString()}';
        });

        // Use ToastManager instead of ScaffoldMessenger
        ToastManager.showError(_errorMessage!);
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      // Get the products directly without using FutureBuilder in the UI
      final products = await _productDb.getAllProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Error loading products', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar produtos: ${e.toString()}';
        });

        // Show error toast
        ToastManager.showError(_errorMessage!);
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Error: $_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use ValueListenableBuilder to rebuild when the products box changes
    return ValueListenableBuilder(
      valueListenable: _productsListenable!,
      builder: (context, box, _) {
        // When the box changes, load products but don't show loading indicator
        // This prevents flickering
        _loadProducts();

        // If we have no products yet, show a message
        if (_products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with edit toggle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Produtos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (true)
                    IconButton(
                      icon: Icon(
                        _isEditMode ? Icons.check : Icons.edit,
                        color: Colors.blue,
                      ),
                      onPressed: _toggleEditMode,
                    ),
                ],
              ),
            ),

            // Product grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];

                  // Calculate position in grid
                  final int row =
                      index ~/ 3; // Integer division by 3 (crossAxisCount)
                  final int col = index % 3; // Remainder when divided by 3

                  // Determine which corners should be rounded
                  final bool roundTopLeft = row == 0 && col == 0;
                  final bool roundTopRight = row == 0 && col == 2;

                  // Check if this is the last row
                  final bool isLastRow = row == (_products.length - 1) ~/ 3;

                  // For the last row, we need to check if it's a full row
                  final bool isFullLastRow = _products.length % 3 == 0;

                  // Adjust bottom corners for partial last rows
                  final bool adjustedRoundBottomLeft = isLastRow && col == 0;
                  final bool adjustedRoundBottomRight =
                      isLastRow &&
                      (isFullLastRow
                          ? col == 2
                          : col == (_products.length % 3) - 1);

                  return ProductCard(
                    key: ValueKey(product.code),
                    code: product.code,
                    name: product.name,
                    category: product.category,
                    isEditMode: _isEditMode,
                    roundTopLeft: roundTopLeft,
                    roundTopRight: roundTopRight,
                    roundBottomLeft: adjustedRoundBottomLeft,
                    roundBottomRight: adjustedRoundBottomRight,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
