import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String name;
  final String unit;
  final double unitValue;
  final double quantity;
  final double total;

  const ProductDetailScreen({
    Key? key,
    required this.name,
    required this.unit,
    required this.unitValue,
    required this.quantity,
    required this.total,
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
            Text('Quantidade: $quantity'),
            Text('Total: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}'),
          ],
        ),
      ),
    );
  }
}
