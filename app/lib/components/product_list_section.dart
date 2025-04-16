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
    _logger.info(
      'Building ProductListSection. Loading: $_isLoading, Products count: ${_products.length}, Error: ${_errorMessage != null}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with edit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produtos',
                style: TextStyle(
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

        // Loading indicator, error message, empty state, or product grid
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          )
        else if (_products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Nenhum produto cadastrado',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              _logger.info(
                'Building grid with constraints: ${constraints.maxWidth}x${constraints.maxHeight}',
              );

              // Use a container with a fixed height
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0, // Perfect square
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    _logger.info(
                      'Building product card for ${product.name} at index $index',
                    );

                    return ShakeWidget(
                      isShaking: _isEditMode,
                      shakeOffset: 1.5, // Subtle shake
                      duration: const Duration(milliseconds: 700),
                      child: ProductCard(
                        name: product.name,
                        code: product.code,
                        category: product.category,
                        isEditMode: _isEditMode,
                        onEditPressed:
                            _isEditMode
                                ? () => _navigateToEditScreen(product)
                                : null,
                      ),
                    );
                  },
                ),
              );
            },
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
