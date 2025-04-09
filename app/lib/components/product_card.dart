import 'package:flutter/material.dart';
import 'package:zuino/screens/product_detail_screen.dart';
import 'package:zuino/database/products_database.dart';

class ProductCard extends StatelessWidget {
  final String codigo;
  final String name;
  final String unit;
  final double unitValue;
  final double quantity;
  final double total;
  final double used;
  final String? category;
  final VoidCallback onStockUpdated;
  final Widget? customFooter; // Add this parameter

  const ProductCard({
    super.key,
    required this.codigo,
    required this.name,
    required this.unit,
    required this.unitValue,
    required this.quantity,
    required this.total,
    required this.used,
    this.category,
    required this.onStockUpdated,
    this.customFooter, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    final currentStock = quantity - used;
    final isOutOfStock = currentStock <= 0;

    return Card(
      color: isOutOfStock ? Colors.red[400] : Colors.grey[800], // Default color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduce padding
        child: GestureDetector(
          behavior:
              HitTestBehavior
                  .opaque, // Ensure taps are only detected on the card itself
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProductDetailScreen(
                      name: name,
                      unit: unit,
                      unitValue: unitValue,
                      quantity: quantity,
                      total: total,
                      used: used,
                      codigo: codigo,
                      category: category,
                    ),
              ),
            );

            if (result == true) {
              onStockUpdated();
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 40,
              ), // Smaller icon
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ), // Smaller font size
                textAlign: TextAlign.center,
                maxLines: 1, // Restrict to one line
                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
              ),
              const SizedBox(height: 4),
              Text(
                'Estoque: ${currentStock.toStringAsFixed(unit == 'kg' ? 3 : 0)} $unit', // Format stock to 3 decimal places
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ), // Smaller font size
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Preço: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ), // Smaller font size
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              const SizedBox(height: 4), // Add extra spacing above the buttons
              customFooter ??
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProductDetailScreen(
                                    name: name,
                                    unit: unit,
                                    unitValue: unitValue,
                                    quantity: quantity,
                                    total: total,
                                    used: used,
                                    codigo: codigo,
                                    category: category,
                                  ),
                            ),
                          );

                          if (result == true) {
                            onStockUpdated();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.blueGrey[600], // Opaque blue-grey color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ), // Button padding
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ), // Centered edit icon
                      ),
                      ElevatedButton(
                        onPressed:
                            isOutOfStock
                                ? () {}
                                : () async {
                                  final productsDb = ProductsDatabase();
                                  final stockBefore = currentStock;

                                  if (unit == 'kg') {
                                    // Show a modal for entering the amount in kg
                                    final amountToSpend = await showDialog<
                                      double
                                    >(
                                      context: context,
                                      builder: (context) {
                                        final controller =
                                            TextEditingController(
                                              text: stockBefore.toStringAsFixed(
                                                3,
                                              ), // Default value
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
                                                    context,
                                                    null,
                                                  ), // Cancel
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final value = double.tryParse(
                                                  controller.text,
                                                );
                                                if (value != null &&
                                                    value > 0 &&
                                                    value <= stockBefore) {
                                                  Navigator.pop(
                                                    context,
                                                    value,
                                                  ); // Confirm
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
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
                                      await productsDb.useProduct(
                                        codigo,
                                        amountToSpend,
                                      ); // Deduct the entered amount
                                      onStockUpdated(); // Notify parent to refresh UI
                                    }
                                  } else {
                                    if (stockBefore >= 1) {
                                      await productsDb.useProduct(
                                        codigo,
                                        1,
                                      ); // Deduct 1 unit
                                      onStockUpdated(); // Notify parent to refresh UI
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Estoque insuficiente para gastar 1 unidade',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isOutOfStock
                                  ? Colors.grey
                                  : Colors.red[400], // Opaque red color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ), // Button padding
                        ),
                        child: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ), // Updated icon
                      ),
                    ],
                  ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
