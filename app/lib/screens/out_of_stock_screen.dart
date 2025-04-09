import 'package:flutter/material.dart';
import 'package:zuino/database/products_database.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/screens/product_detail_screen.dart'; // Add this import

class OutOfStockScreen extends StatefulWidget {
  const OutOfStockScreen({Key? key}) : super(key: key);

  @override
  State<OutOfStockScreen> createState() => _OutOfStockScreenState();
}

class _OutOfStockScreenState extends State<OutOfStockScreen> {
  final _productsDb = ProductsDatabase();
  final _logger = Logger('OutOfStockScreen');

  List<Map<String, dynamic>> outOfStockProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutOfStockProducts();
  }

  Future<void> _loadOutOfStockProducts() async {
    setState(() {
      isLoading = true;
    });

    final products = await ProductsDatabase().getOutOfStockProducts();

    // Sort products alphabetically by name
    products.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );

    setState(() {
      outOfStockProducts = products;
      isLoading = false;
    });
  }

  Future<void> _deleteProduct(String codigo, String name) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Produto'),
            content: Text('Tem certeza que deseja excluir "$name"?'),
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
        _logger.info('Deleting product with code: $codigo');

        // Use removeProduct to delete the product
        await _productsDb.removeProduct(codigo);

        _logger.info('Product deleted successfully');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso')),
        );

        // Reload the list
        _loadOutOfStockProducts();
      } catch (e) {
        _logger.error('Error deleting product', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir produto: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos em Falta')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : outOfStockProducts.isEmpty
              ? const Center(
                child: Text(
                  'Nenhum produto em falta',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      1.0, // Changed from 0.8 to 1.0 to match main screen
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: outOfStockProducts.length,
                itemBuilder: (context, index) {
                  final product = outOfStockProducts[index];

                  // Create a row with two buttons to match the main screen layout
                  final customFooter = Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProductDetailScreen(
                                    name: product['name'] as String,
                                    unit: product['unit'] as String,
                                    unitValue:
                                        (product['unitValue'] as num)
                                            .toDouble(),
                                    quantity:
                                        (product['quantity'] as num).toDouble(),
                                    total:
                                        (product['total'] as num?)
                                            ?.toDouble() ??
                                        ((product['unitValue'] as num)
                                                .toDouble() *
                                            (product['quantity'] as num)
                                                .toDouble()),
                                    used: (product['used'] as num).toDouble(),
                                    codigo: product['codigo'].toString(),
                                    category: product['category'] as String?,
                                  ),
                            ),
                          );

                          if (result == true) {
                            _loadOutOfStockProducts();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => _deleteProduct(
                              product['codigo'].toString(),
                              product['name'] as String,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  );

                  return ProductCard(
                    codigo: product['codigo'].toString(),
                    name: product['name'] as String,
                    unit: product['unit'] as String,
                    unitValue: (product['unitValue'] as num).toDouble(),
                    quantity: (product['quantity'] as num).toDouble(),
                    total:
                        (product['total'] as num?)?.toDouble() ??
                        ((product['unitValue'] as num).toDouble() *
                            (product['quantity'] as num).toDouble()),
                    used: (product['used'] as num).toDouble(),
                    category: product['category'] as String?,
                    onStockUpdated: _loadOutOfStockProducts,
                    customFooter: customFooter,
                  );
                },
              ),
    );
  }
}
