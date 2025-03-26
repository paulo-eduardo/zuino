import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Unit: $unit'),
            Text('Unit Price: \$${unitValue.toStringAsFixed(2)}'),
            Text('Quantity: ${quantity.toStringAsFixed(2)}'),
            Text('Total: \$${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
