import 'package:flutter/material.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/categories_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/utils/toast_manager.dart'; // Add this import

class EditProductScreen extends StatefulWidget {
  final String codigo;
  final Function? onProductUpdated;

  const EditProductScreen({
    super.key,
    required this.codigo,
    this.onProductUpdated,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _productDb = ProductDatabase();
  final _categoriesDb = CategoriesDatabase();
  final _logger = Logger('EditProductScreen');

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasChanges = false;
  List<String> _categories = [];
  Product? _currentProduct;

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadCategories();
  }

  Future<void> _loadProductData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final product = await _productDb.getProduct(widget.codigo);

      if (product != null) {
        setState(() {
          _currentProduct = product;
          _nameController.text = product.name;
          _categoryController.text = product.category;
          _isLoading = false;
        });
      } else {
        _logger.error('Product not found with code: ${widget.codigo}');
        if (mounted) {
          ToastManager.showError('Produto não encontrado');
          Navigator.pop(context);
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error loading product data', e, stackTrace);
      if (mounted) {
        ToastManager.showError('Erro ao carregar dados: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesDb.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      _logger.error('Error loading categories', e);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      if (!mounted) return;
      ToastManager.showError('Nome do produto não pode estar vazio');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_currentProduct == null) {
        throw Exception('Product not found in database');
      }

      // Create a new product instance with updated values
      final updatedProduct = _currentProduct!.copyWith(
        name: _nameController.text,
        category: _categoryController.text,
      );

      // Save the updated product
      await _productDb.insertOrUpdate(updatedProduct);

      // Add the category if it's new
      if (_categoryController.text.isNotEmpty) {
        await _categoriesDb.addCategory(_categoryController.text);
      }

      if (mounted) {
        // Show success message
        ToastManager.showSuccess('Produto atualizado com sucesso');

        // Reset the changes flag
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });

        // Call the callback if provided
        if (widget.onProductUpdated != null) {
          widget.onProductUpdated!();
        }

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
        ToastManager.showError('Erro ao salvar alterações: ${e.toString()}');
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Produto'),
        actions: [
          if (_hasChanges && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Salvar alterações',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product code display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código do Produto',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          widget.codigo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Produto',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 16),

          // Category field with dropdown
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _categories.where(
                (category) => category.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (String selection) {
              _categoryController.text = selection;
              _onFieldChanged();
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onFieldSubmitted,
            ) {
              // Use the existing controller
              controller.text = _categoryController.text;

              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      _categoryController.clear();
                      _onFieldChanged();
                    },
                  ),
                ),
                onChanged: (value) {
                  _categoryController.text = value;
                  _onFieldChanged();
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('SALVAR ALTERAÇÕES'),
            ),
          ),
        ],
      ),
    );
  }
}
