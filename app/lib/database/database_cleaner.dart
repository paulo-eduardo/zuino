import 'package:flutter/material.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/utils/logger.dart';

class DatabaseCleaner {
  final ProductDatabase _productDb;
  final ReceiptsDatabase _receiptDb;
  final Logger _logger = Logger('DatabaseCleaner');

  DatabaseCleaner({
    required ProductDatabase productDb,
    required ReceiptsDatabase receiptDb,
  }) : _productDb = productDb,
       _receiptDb = receiptDb;

  Future<void> clearAllData(BuildContext context) async {
    try {
      final shouldClear = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Limpar Produtos e Recibos'),
              content: const Text(
                'Tem certeza que deseja limpar todos os produtos e recibos? Esta ação não pode ser desfeita.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Limpar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (shouldClear == true) {
        // Clear products
        await _productDb.clearAll();

        // Clear receipts
        await _receiptDb.clearAll();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produtos e recibos limpos com sucesso'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error clearing product and receipt data', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar dados: ${e.toString()}')),
        );
      }
    }
  }
}
