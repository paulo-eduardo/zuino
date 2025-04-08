import 'package:flutter/material.dart';
import 'package:mercadinho/components/product_card.dart';
import 'package:mercadinho/database/products_database.dart';

class OutOfStockScreen extends StatefulWidget {
  const OutOfStockScreen({super.key});

  @override
  State<OutOfStockScreen> createState() => _OutOfStockScreenState();
}

class _OutOfStockScreenState extends State<OutOfStockScreen> {
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
                  'Não há produtos em falta no momento.',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                    itemCount: outOfStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = outOfStockProducts[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: ProductCard(
                          codigo: product['codigo'],
                          name: product['name'],
                          unit: product['unit'],
                          unitValue: product['unitValue'],
                          quantity: product['quantity'],
                          total: product['unitValue'] * product['quantity'],
                          used: product['used'] ?? 0,
                          onStockUpdated: () {
                            _loadOutOfStockProducts();
                            // Set result to true to trigger refresh on StockScreen
                            Navigator.pop(context, true);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
