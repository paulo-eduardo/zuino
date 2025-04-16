import 'package:flutter/material.dart';
import 'package:zuino/database/inventory_database.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/components/item_card.dart'; // Changed from product_card to item_card

class OutOfStockScreen extends StatefulWidget {
  const OutOfStockScreen({super.key});

  @override
  State<OutOfStockScreen> createState() => _OutOfStockScreenState();
}

class _OutOfStockScreenState extends State<OutOfStockScreen> {
  final _inventoryDb = InventoryDatabase();
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

    final products = await _inventoryDb.getOutOfStockItems();

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
      appBar: AppBar(
        title: const Text('Produtos em Falta'),
        actions: [
          // Add the counter badge to the AppBar
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.inventory_2_outlined),
                tooltip: 'Produtos em falta',
                onPressed: () {
                  // This is already the out-of-stock screen, so no navigation needed
                },
              ),
              if (!isLoading && outOfStockProducts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${outOfStockProducts.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
                      0.85, // Match the aspect ratio from stock_screen
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: outOfStockProducts.length,
                itemBuilder: (context, index) {
                  final product = outOfStockProducts[index];
                  final name = product['name'] as String;
                  final codigo = product['codigo'].toString();

                  return ItemCard(
                    name: name,
                    stock: product['stock'],
                    codigo: codigo,
                    unit: product['unit'],
                    price: product['lastUnitValue'],
                    onItemUpdated: () {
                      // Reload the list when an item is updated
                      _loadOutOfStockProducts();
                    },
                  );
                },
              ),
    );
  }
}
