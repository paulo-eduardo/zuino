import 'package:flutter/material.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/utils/logger.dart';

class CustomSearchModal extends StatefulWidget {
  final VoidCallback onActionButtonPressed;

  const CustomSearchModal({super.key, required this.onActionButtonPressed});

  @override
  State<CustomSearchModal> createState() => _CustomSearchModalState();
}

class _CustomSearchModalState extends State<CustomSearchModal>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _productDb = ProductDatabase();
  final _logger = Logger('CustomSearchModal');

  bool _isSearching = false;
  bool _isModalOpen = false;
  List<Product> _filteredProducts = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isModalOpen) {
      setState(() {
        _isModalOpen = true;
      });
      _animationController.forward();
      _searchProducts();
    }
  }

  void _onSearchChanged() {
    final searchTerm = _searchController.text.trim();
    setState(() {
      _isSearching = searchTerm.isNotEmpty;
    });

    if (_isModalOpen) {
      _searchProducts();
    }
  }

  Future<void> _searchProducts() async {
    final searchTerm = _searchController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      List<Product> products;
      if (searchTerm.isEmpty) {
        products = await _productDb.getAllProducts();
      } else {
        products = await _productDb.getProductsByName(searchTerm);
      }

      if (mounted) {
        setState(() {
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Error searching products', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _closeModal() {
    _focusNode.unfocus();
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isModalOpen = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Modal overlay
        if (_isModalOpen)
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: GestureDetector(
                    onTap: _closeModal,
                    child: Container(color: Colors.black54, child: child),
                  ),
                );
              },
              child: GestureDetector(
                onTap:
                    () {}, // Prevent taps from closing the modal when tapping on content
                child: _buildModalContent(),
              ),
            ),
          ),

        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search TextField
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Eu preciso de...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon:
                        _isSearching
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
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

              // Action Button
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add),
                  color: Colors.white,
                  onPressed: widget.onActionButtonPressed,
                  tooltip: 'Opções',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModalContent() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            MediaQuery.of(context).size.height * (1 - _animation.value) * 0.3,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produtos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _closeModal,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Products list
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Nenhum produto encontrado',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
              : SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ProductCard(
                      code: product.code,
                      name: product.name,
                      category: product.category,
                      isEditMode: false,
                      roundTopLeft: true,
                      roundTopRight: true,
                      roundBottomLeft: true,
                      roundBottomRight: true,
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
