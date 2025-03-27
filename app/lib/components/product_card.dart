import 'package:flutter/material.dart';
import 'package:mercadinho/screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String unit;
  final double unitValue;
  final double quantity;
  final double total;

  const ProductCard({
    Key? key,
    required this.name,
    required this.unit,
    required this.unitValue,
    required this.quantity,
    required this.total,
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
              'Estoque: $quantity $unit',
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
                  onPressed: () {
                    if (unit == 'kg') {
                      final newQuantity = quantity - 0.1;
                      if (newQuantity >= 0) {
                        // Update logic here
                      }
                    } else {
                      final newQuantity = quantity - 1;
                      if (newQuantity >= 0) {
                        // Update logic here
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
                  child: const Icon(Icons.remove_circle, color: Colors.white, size: 24), // Centered remove icon
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
