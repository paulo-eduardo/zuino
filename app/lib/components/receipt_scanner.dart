import 'dart:async'; // Add this import for Completer
import 'package:flutter/material.dart';
import 'package:zuino/components/qr_code_reader.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/services/api_servive.dart';
import 'package:zuino/utils/toast_manager.dart'; // Add this import

class ReceiptScanner {
  final BuildContext context;
  final VoidCallback onScanComplete;
  final Logger _logger = Logger('ReceiptScanner');
  final ProductDatabase _productDb = ProductDatabase();
  final ReceiptsDatabase _receiptDb = ReceiptsDatabase();
  final ShoppingListDatabase _shoppingListDb = ShoppingListDatabase();

  ReceiptScanner({required this.context, required this.onScanComplete});

  Future<void> scanReceipt() async {
    bool dialogCompleted = false;
    bool isDialogOpen = false;

    try {
      // Show loading dialog
      if (context.mounted) {
        isDialogOpen = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Processando QR Code..."),
                ],
              ),
            );
          },
        ).then((_) {
          dialogCompleted = true;
        });
      }

      // Function to close dialog
      void closeDialog() {
        if (isDialogOpen && context.mounted && !dialogCompleted) {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogOpen = false;
          dialogCompleted = true;
        }
      }

      // Launch QR code scanner
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRCodeReader()),
      );

      if (result != null) {
        final url = result.toString();

        // Close QR code dialog
        closeDialog();

        // Show processing toast
        if (context.mounted) {
          ToastManager.showProcessing('Processando recibo...', context);
        }

        // Process the URL and save data
        await _processReceiptUrl(url);
      } else {
        // If no result, close the dialog
        closeDialog();
        return;
      }

      // Close dialog if still open
      closeDialog();

      // Call the callback to refresh the UI
      onScanComplete();
    } catch (e) {
      _logger.error('Error scanning receipt: $e');

      // Close dialog if it's still open
      if (isDialogOpen && context.mounted && !dialogCompleted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message
      ToastManager.showError('Erro ao processar compra: ${e.toString()}');
    }
  }

  Future<void> _processReceiptUrl(String url) async {
    if (!context.mounted) return;

    try {
      // First check if receipt already exists in database
      final hasReceipt = await _receiptDb.hasReceipt(url);

      if (!context.mounted) return;

      if (hasReceipt) {
        // Show warning message
        ToastManager.showWarning(
          'Este recibo já foi processado anteriormente.',
        );
        return;
      }

      // Update processing message
      if (context.mounted) {
        ToastManager.cancelProcessing();
        ToastManager.showProcessing('Obtendo dados do recibo...', context);
      }

      // Make API request using ApiService
      final responseData = await ApiService.post('receipt/scan', {'url': url});

      if (!context.mounted) return;

      // Extract receipt data
      final receiptData = responseData['receipt'];
      final items = responseData['items'] as List;

      // Update processing message
      if (context.mounted) {
        ToastManager.cancelProcessing();
        ToastManager.showProcessing(
          'Salvando ${items.length} itens...',
          context,
        );
      }

      // Format items for both databases in a single loop
      final List<Map<String, dynamic>> productItems = [];
      final List<Map<String, dynamic>> receiptItems = [];

      for (var item in items) {
        try {
          // Parse numeric values safely
          final double quantity = _safeParseDouble(item['quantity']);
          final double unitValue = _safeParseDouble(item['unitValue']);
          final double total = quantity * unitValue;

          // Format for product database
          productItems.add({
            'code': item['codigo'],
            'name': item['name'],
            'category': item['category'] ?? 'Outros',
            'unitValue': item['unitValue'] ?? 0.0,
          });

          // Format for receipt database
          receiptItems.add({
            'productCode': item['codigo'],
            'quantity': quantity.toString(),
            'unit': item['unit'],
            'unitValue': unitValue.toString(),
            'total': total.toString(),
          });
        } catch (e) {
          // Log error and continue with next item
          _logger.error(
            'Error processing item: ${item['name'] ?? 'Unknown'} - $e',
          );
          continue;
        }
      }

      // Parse date from string to DateTime
      final receiptDate = DateTime.parse(receiptData['date']);

      // Save receipt to database using URL as the unique identifier
      await _receiptDb.saveReceipt(
        url: receiptData['url'],
        store: receiptData['store'],
        date: receiptDate,
        totalAmount: double.parse(receiptData['totalAmount'].toString()),
        paymentMethod: receiptData['paymentMethod'],
        items: receiptItems,
      );

      // Process each product item
      for (var productItem in productItems) {
        // Create product object and save to database
        final product = Product(
          code: productItem['code'],
          name: productItem['name'],
          category: productItem['category'],
          lastUnitPrice: productItem['unitValue'],
        );

        await _productDb.insertOrUpdate(product);

        // Remove item from shopping list if it exists
        await _shoppingListDb.removeItem(productItem['code']);
      }

      if (!context.mounted) return;

      // Cancel the processing toast
      ToastManager.cancelProcessing();

      // Show a success notification
      ToastManager.showSuccess(
        'Recibo processado com sucesso. ${items.length} itens adicionados.',
      );
    } catch (e) {
      if (!context.mounted) return;

      // Cancel the processing toast
      ToastManager.cancelProcessing();

      // Show error message with details
      ToastManager.showError('Falha ao processar recibo: ${e.toString()}');

      // Rethrow to be caught by the parent method
      throw Exception('Failed to process receipt: $e');
    }
  }

  // Helper method to safely parse double values
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}
