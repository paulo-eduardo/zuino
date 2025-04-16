import 'package:flutter/material.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/screens/edit_product_screen.dart';
import 'package:zuino/utils/logger.dart';

// ShakeWidget implementation
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
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _setupAnimation();

    if (widget.isShaking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShaking != oldWidget.isShaking) {
      if (widget.isShaking) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }

    if (widget.shakeOffset != oldWidget.shakeOffset) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    _offsetAnimation = Tween<double>(
      begin: -widget.shakeOffset,
      end: widget.shakeOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.isShaking ? _offsetAnimation.value : 0, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _logger.info('ProductListSection initialized');
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.info('ProductListSection dependencies changed');
  }

  @override
  void didUpdateWidget(ProductListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.info('ProductListSection widget updated');
  }

  Future<void> _loadProducts() async {
    _logger.info('Starting to load products');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _logger.info('Set loading state to true');

      final products = await _productDb.getAllProducts();
      _logger.info('Products loaded successfully. Count: ${products.length}');

      if (products.isNotEmpty) {
        _logger.info(
          'First product: ${products.first.name}, Code: ${products.first.code}',
        );
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
        _logger.info('State updated with products');
      } else {
        _logger.warning('Widget not mounted after loading products');
      }
    } catch (e, stackTrace) {
      _logger.error('Error loading products', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar produtos: ${e.toString()}';
        });
        _logger.info('Set error state: $_errorMessage');

        // Show a snackbar with the error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
        _logger.info('Displayed error snackbar');
      } else {
        _logger.warning('Widget not mounted after error');
      }
    }
  }

  void _toggleEditMode() {
    _logger.info('Toggling edit mode from $_isEditMode to ${!_isEditMode}');
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _navigateToEditScreen(Product product) {
    _logger.info(
      'Navigating to edit screen for product: ${product.name} (${product.code})',
    );

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
                _logger.info('Product updated callback received');
                // Reload products when returning from edit screen
                _loadProducts();
              },
            ),
      ),
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with edit toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produtos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
              final bool roundBottomLeft =
                  (row == (_products.length - 1) ~/ 3) && col == 0;
              final bool roundBottomRight =
                  (row == (_products.length - 1) ~/ 3) && col == 2;

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
                code: product.code,
                name: product.name,
                category: product.category,
                onProductAdded: () {},
                isEditMode: _isEditMode,
                onEditPressed: () => _navigateToEditScreen(product),
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
  }

  @override
  void dispose() {
    _logger.info('ProductListSection disposed');
    super.dispose();
  }
}
