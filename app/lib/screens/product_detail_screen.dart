import 'package:flutter/material.dart';
import 'package:zuino/database/products_database.dart';
import 'package:zuino/database/categories_database.dart';
import 'package:zuino/utils/logger.dart';

class ProductDetailScreen extends StatefulWidget {
  final String name;
  final String unit;
  final double unitValue;
  final double quantity;
  final double total;
  final double used;
  final String codigo;
  final String? category;

  const ProductDetailScreen({
    super.key,
    required this.name,
    required this.unit,
    required this.unitValue,
    required this.quantity,
    required this.total,
    required this.used,
    required this.codigo,
    this.category,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productsDb = ProductsDatabase();
  final _categoriesDb = CategoriesDatabase();
  final _logger = Logger('ProductDetailScreen');

  late TextEditingController _nameController;
  late TextEditingController _categoryController;

  bool _isSaving = false;
  List<String> _categories = [];
  bool _hasChanges = false; // Flag to track if changes were made

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);

    // Initialize with the category from widget if available
    _categoryController = TextEditingController(text: widget.category ?? '');

    // Add listeners to detect changes
    _nameController.addListener(_checkForChanges);
    _categoryController.addListener(_checkForChanges);

    // Load product data from database to get the latest category
    _loadProductFromDatabase();
    _loadCategories();
  }

  // Modify the _loadProductFromDatabase method to handle dynamic maps correctly
  Future<void> _loadProductFromDatabase() async {
    try {
      // Use the new method that ensures proper typing
      final products = await _productsDb.getTypedProducts();
      _logger.info('Retrieved ${products.length} products from database');

      final matchingProduct = products.firstWhere(
        (p) => p['codigo'] == widget.codigo,
        orElse: () => <String, dynamic>{},
      );

      if (matchingProduct.isNotEmpty) {
        _logger.info('Found product in database: $matchingProduct');

        if (mounted) {
          setState(() {
            final category = matchingProduct['category'] ?? '';
            _categoryController.text = category.toString();
            _logger.info('Loaded category from database: $category');
          });
        }
      } else {
        _logger.error('Product not found in database: ${widget.codigo}');
      }
    } catch (e, stackTrace) {
      _logger.error('Error loading product from database', e, stackTrace);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesDb.getCategories();
      if (mounted) {
        // Added mounted check
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      _logger.error('Error loading categories', e);
    }
  }

  // Method to check if any changes were made
  void _checkForChanges() {
    final nameChanged = _nameController.text != widget.name;
    final categoryChanged = _categoryController.text != (widget.category ?? '');

    setState(() {
      _hasChanges = nameChanged || categoryChanged;
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _nameController.removeListener(_checkForChanges);
    _categoryController.removeListener(_checkForChanges);

    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do produto não pode estar vazio')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      _logger.info(
        'Starting to save product changes for code: ${widget.codigo}',
      );

      // Create a completely new product map with all required fields
      final Map<String, dynamic> updatedProduct = {
        'codigo': widget.codigo,
        'name': _nameController.text,
        'unit': widget.unit,
        'unitValue': widget.unitValue,
        'quantity': widget.quantity,
        'total': widget.total,
        'used': widget.used,
        'category': _categoryController.text,
      };

      _logger.info('Created updated product map: $updatedProduct');

      // Save the updated product
      await _productsDb.insertOrUpdateProduct(updatedProduct);
      _logger.info('Product saved successfully');

      // Add the category if it's new
      if (_categoryController.text.isNotEmpty) {
        await _categoriesDb.addCategory(_categoryController.text);
        _logger.info('Category added/updated: ${_categoryController.text}');
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso')),
        );

        // Reset the changes flag
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });

        // Return to previous screen after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(
              context,
              true,
            ); // Return true to indicate changes were made
          }
        });
      }
    } catch (e) {
      _logger.error('Error saving product changes', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar alterações: ${e.toString()}')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteProduct() async {
    // Show confirmation dialog
    if (!mounted) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Produto'),
            content: Text('Tem certeza que deseja excluir "${widget.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        setState(() {
          _isSaving = true; // Show loading indicator
        });

        _logger.info('Deleting product with code: ${widget.codigo}');

        // Use removeProduct instead of deleteProduct
        await _productsDb.removeProduct(widget.codigo);

        _logger.info('Product deleted successfully');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso')),
          );

          // Return to previous screen after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(
                context,
                true,
              ); // Return true to indicate changes were made
            }
          });
        }
      } catch (e) {
        _logger.error('Error deleting product', e);
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir produto: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStock = widget.quantity - widget.used;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Produto'),
        actions: [
          // Save button in app bar
          if (_hasChanges)
            IconButton(
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveChanges,
              tooltip: 'Salvar alterações',
            ),
        ],
      ),
      body:
          _isSaving && !mounted
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image or Icon
                    Center(
                      child: Container(
                        width: 100, // Smaller size
                        height: 100, // Smaller size
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 50, // Smaller icon
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Reduced spacing
                    // Product Name - Smaller field
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Nome do Produto',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 40, // Smaller height
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: 'Nome do produto',
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    // Product Category - Smaller field with autocomplete
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Categoria',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 40, // Smaller height
                            child: Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: _categoryController.text,
                              ),
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                if (textEditingValue.text.isEmpty) {
                                  return _categories;
                                }
                                return _categories.where(
                                  (category) => category.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              onSelected: (String selection) {
                                setState(() {
                                  _categoryController.text = selection;
                                  _checkForChanges();
                                });
                              },
                              fieldViewBuilder: (
                                BuildContext context,
                                TextEditingController controller,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                // Update the controller with our category controller's text
                                // This ensures the field shows the current category
                                if (controller.text !=
                                    _categoryController.text) {
                                  controller.text = _categoryController.text;
                                }

                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    hintText: 'Categoria',
                                    suffixIcon: Icon(Icons.category, size: 18),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onChanged: (value) {
                                    _categoryController.text = value;
                                    _checkForChanges();
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    // Product Code - Smaller text
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Código',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            widget.codigo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    // Divider
                    const Divider(),
                    const SizedBox(height: 12), // Reduced spacing
                    // Stock Information - More compact layout
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estoque Atual',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentStock.toStringAsFixed(widget.unit == 'kg' ? 3 : 0)} ${widget.unit}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: currentStock <= 0 ? Colors.red : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estoque Inicial',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.quantity.toStringAsFixed(widget.unit == 'kg' ? 3 : 0)} ${widget.unit}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    // Price Information - More compact layout
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preço Unitário',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'R\$ ${widget.unitValue.toStringAsFixed(2).replaceAll('.', ',')}/${widget.unit}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Valor Total',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'R\$ ${widget.total.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Show "Use Product" button if there's stock, otherwise show "Delete Product" button
                    Center(
                      child:
                          currentStock > 0
                              ? ElevatedButton.icon(
                                onPressed: () async {
                                  // Show dialog to use product
                                  if (widget.unit == 'kg') {
                                    // Store context before async gap
                                    final currentContext = context;

                                    // Show a modal for entering the amount in kg
                                    final amountToSpend = await showDialog<
                                      double
                                    >(
                                      context: currentContext,
                                      builder: (dialogContext) {
                                        final controller =
                                            TextEditingController(
                                              text: currentStock
                                                  .toStringAsFixed(3),
                                            );
                                        return AlertDialog(
                                          title: const Text('Gastar em KG'),
                                          content: TextField(
                                            controller: controller,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              labelText: 'Quantidade em KG',
                                              hintText: 'Ex: 1.234',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    dialogContext,
                                                    null,
                                                  ),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final value = double.tryParse(
                                                  controller.text,
                                                );
                                                if (value != null &&
                                                    value > 0 &&
                                                    value <= currentStock) {
                                                  Navigator.pop(
                                                    dialogContext,
                                                    value,
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    dialogContext,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Quantidade inválida',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Confirmar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (amountToSpend != null) {
                                      await _productsDb.useProduct(
                                        widget.codigo,
                                        amountToSpend,
                                      );
                                      Navigator.pop(
                                        context,
                                        true,
                                      ); // Return true to indicate changes were made
                                    }
                                  } else {
                                    // For unit products, just use 1
                                    await _productsDb.useProduct(
                                      widget.codigo,
                                      1,
                                    );
                                    Navigator.pop(
                                      context,
                                      true,
                                    ); // Return true to indicate changes were made
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                                label: const Text('Usar Produto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[400],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              )
                              : ElevatedButton.icon(
                                onPressed: _deleteProduct,
                                icon: const Icon(Icons.delete_forever),
                                label: const Text('Excluir Produto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
