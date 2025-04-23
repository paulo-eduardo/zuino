import 'package:flutter/material.dart';
import 'package:zuino/components/base_item_card.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/utils/toast_manager.dart';

class ShoppingSearchModal extends StatefulWidget {
  const ShoppingSearchModal({super.key});

  @override
  State<ShoppingSearchModal> createState() => _ShoppingSearchModalState();
}

class _ShoppingSearchModalState extends State<ShoppingSearchModal>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _productDb = ProductDatabase();
  final _logger = Logger('ShoppingSearchModal');

  bool _isSearching = false;
  List<Product> _filteredProducts = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  // Minimum height for the modal to display content
  final double _minModalHeight = 200.0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animation with a smoother curve
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart, // Smoother curve for better expansion feel
    );

    // Start animation
    _animationController.forward();

    // Request focus to show keyboard automatically
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });

    // Remove the keyboard visibility listener that's causing navigation issues
    // We'll handle closing manually with a back button or gesture

    // Load initial products
    _searchProducts();
  }

  void _onSearchChanged() {
    final searchTerm = _searchController.text.trim();
    setState(() {
      _isSearching = searchTerm.isNotEmpty;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (searchTerm == _searchController.text.trim()) {
        _searchProducts();
      }
    });
  }

  Future<void> _searchProducts() async {
    final searchTerm = _searchController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      if (searchTerm.isEmpty) {
        // If search is empty, show an empty list instead of recent products
        setState(() {
          _filteredProducts = [];
          _isLoading = false;
        });
      } else {
        // Search for products matching the term
        final products = await _productDb.getProductsByName(searchTerm);
        setState(() {
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error searching products', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
    });
    _searchProducts(); // This will now load recent products
    _focusNode.requestFocus(); // Keep focus on the search field
  }

  void _handleNewProductCardTap() async {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) return;

    try {
      // Create a new product with the search text as the name
      final newProduct = Product(
        code: searchText,
        name: searchText,
        category: 'Outros', // Default category
      );

      // Save the product to the database
      await _productDb.insertOrUpdate(newProduct);

      // Add the product to the shopping list
      final shoppingListDb = ShoppingListDatabase();
      final shoppingItem = ShoppingItem(productCode: searchText, quantity: 1.0);
      await shoppingListDb.addOrUpdateItem(shoppingItem);

      // Clear the search and close the modal
      _clearSearch();
    } catch (e) {
      _logger.error('Error creating new product', e);
      ToastManager.showError('Erro ao criar produto: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Calculate the available height (screen height minus keyboard height)
    final availableHeight = screenSize.height * 0.8 - keyboardHeight;

    // Calculate the maximum height (80% of available height)
    final maxModalHeight = availableHeight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate the current animated height
        final currentHeight = maxModalHeight * _animation.value;

        // Determine if we should show content based on minimum height
        final showContent = currentHeight >= _minModalHeight;

        return Padding(
          // Add padding at the bottom equal to keyboard height to push the modal up
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 0) {
                  final newValue =
                      _animationController.value -
                      (details.primaryDelta! / 500);
                  _animationController.value = newValue.clamp(0.0, 1.0);
                  if (_animationController.value < 0.7) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: SizedBox(
                height: currentHeight,
                width: screenSize.width,
                child: showContent ? child : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          // Use SafeArea to avoid system UI overlaps
          child: SafeArea(
            // Only apply bottom padding
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Only show certain elements if we have enough height
                final hasEnoughHeight = constraints.maxHeight >= 200;
                final hasFullHeight = constraints.maxHeight >= 400;

                return Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Results title - only show if we have enough height
                    if (hasEnoughHeight)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _searchController.text.trim().isEmpty
                                  ? 'Digite para buscar produtos'
                                  : 'Resultados da busca',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Results list - only show if we have full height
                    // Results list - only show if we have full height
                    if (hasFullHeight)
                      Flexible(
                        child:
                            _searchController.text.trim().isEmpty
                                ? Center(
                                  child: Text(
                                    _isLoading
                                        ? 'Carregando...'
                                        : 'Digite algo para buscar produtos',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                )
                                : GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 0,
                                        mainAxisSpacing: 0,
                                      ),
                                  // Add +1 to always include the "New Product" card at the end
                                  itemCount:
                                      _isLoading
                                          ? 0
                                          : _filteredProducts.length + 1,
                                  itemBuilder: (context, index) {
                                    // If we're at the last index, show the "New Product" card
                                    if (index == _filteredProducts.length) {
                                      final searchText =
                                          _searchController.text.trim();
                                      return BaseItemCard(
                                        name: searchText,
                                        category: 'Novo produto',
                                        roundTopLeft: false,
                                        roundTopRight: false,
                                        roundBottomLeft:
                                            _filteredProducts.length % 3 == 0,
                                        roundBottomRight:
                                            _filteredProducts.length % 3 == 2,
                                        fixedSize: true,
                                        onTap: _handleNewProductCardTap,
                                      );
                                    }

                                    // Otherwise, show a product card
                                    final product = _filteredProducts[index];

                                    // Calculate position in grid
                                    final int row = index ~/ 3;
                                    final int col = index % 3;

                                    // Total number of items including the "New Product" card
                                    final totalItems =
                                        _filteredProducts.length + 1;
                                    final lastRow = (totalItems - 1) ~/ 3;

                                    // Determine which corners should be rounded
                                    final bool roundTopLeft =
                                        row == 0 && col == 0;
                                    final bool roundTopRight =
                                        row == 0 && col == 2;
                                    final bool roundBottomLeft =
                                        row == lastRow &&
                                        col == 0 &&
                                        index == totalItems - 3;
                                    final bool roundBottomRight =
                                        row == lastRow &&
                                        col == 2 &&
                                        index == totalItems - 2;

                                    return ProductCard(
                                      key: ValueKey(product.code),
                                      code: product.code,
                                      name: product.name,
                                      category: product.category,
                                      roundTopLeft: roundTopLeft,
                                      roundTopRight: roundTopRight,
                                      roundBottomLeft: roundBottomLeft,
                                      roundBottomRight: roundBottomRight,
                                      onCardTap: () {
                                        // Clear the search field and keep focus
                                        _clearSearch();
                                      },
                                    );
                                  },
                                ),
                      ),
                    // Search bar at the bottom - always show
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white),
                        // Disable autocorrect and suggestions
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        // Disable capitalization
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                          hintText: "Buscar produtos...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon:
                              _isSearching
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                  : null,
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
