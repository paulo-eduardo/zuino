import 'package:flutter/material.dart';
import 'package:mercadinho/screens/product_detail_screen.dart';
import 'package:mercadinho/database/products_database.dart';
import 'package:hive/hive.dart'; // Add this import for Hive

class ProductCard extends StatelessWidget {
  final String codigo;
  final String name;
  final String unit;
  final double unitValue;
  final double quantity;
  final double total;
  final double used;
  final VoidCallback onStockUpdated; // Add a callback for stock updates

  const ProductCard({
    Key? key,
    required this.codigo,
    required this.name,
    required this.unit,
    required this.unitValue,
    required this.quantity,
    required this.total,
    required this.used,
    required this.onStockUpdated, // Add the callback to the constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduce padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, color: Colors.white, size: 40), // Smaller icon
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), // Smaller font size
              textAlign: TextAlign.center,
              maxLines: 1, // Restrict to one line
              overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
            ),
            const SizedBox(height: 6),
            Text(
              'Estoque: ${quantity - used} $unit', // Update to show quantity - used
              style: const TextStyle(color: Colors.white70, fontSize: 12), // Smaller font size
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Preço: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(color: Colors.white70, fontSize: 12), // Smaller font size
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          name: name,
                          unit: unit,
                          unitValue: unitValue,
                          quantity: quantity,
                          total: total,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[600], // Opaque blue-grey color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Button padding
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 24), // Centered edit icon
                ),
                ElevatedButton(
                  onPressed: () async {
                    final productsDb = ProductsDatabase();
                    final stockBefore = quantity - used;

                    if (unit == 'KG') {
                      // Show a toast message for products with unit 'kg'
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Não é possível gastar produtos com unidade em kg')),
                      );
                    } else {
                      if (stockBefore >= 1) {
                        await productsDb.useProduct(codigo, 1); // Deduct 1 unit
                        onStockUpdated(); // Notify parent to refresh UI
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Estoque insuficiente para gastar 1 unidade')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400], // Opaque red color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Button padding
                  ),
                  child: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 24), // Updated icon
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
