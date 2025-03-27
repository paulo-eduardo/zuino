import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String name;
  final String unit;
  final double unitValue;
  final double quantity;
  final double total;
  final double used; // Add used field

  const ProductDetailScreen({
    Key? key,
    required this.name,
    required this.unit,
    required this.unitValue,
    required this.quantity,
    required this.total,
    required this.used, // Add used to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Produto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Nome: $name'),
            Text('Unidade: $unit'),
            Text('Preço Unitário: R\$ ${unitValue.toStringAsFixed(2).replaceAll('.', ',')}'),
            Text('Quantidade Total: $quantity $unit'), // Add quantity
            Text('Quantidade Usada: $used $unit'), // Add used
            Text('Estoque Disponível: ${(quantity - used).toStringAsFixed(unit == 'KG' ? 3 : 0)} $unit'), // Add stock
            const SizedBox(height: 16),
            Text(
              'Total: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
