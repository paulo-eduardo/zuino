import 'dart:async'; // Add this import for Completer
import 'package:flutter/material.dart';
import 'package:zuino/components/qr_code_reader.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/services/api_servive.dart';

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

      // Store context mounted state before async operations
      final bool wasContextMounted = context.mounted;

      if (result != null) {
        final url = result.toString();
        _logger.info('QR Code scanned: $url');

        // Process the URL and save data
        await _processReceiptUrl(url);
      } else {
        // If no result, close the dialog
        closeDialog();
        return;
      }

      // Close dialog when done
      closeDialog();

      // Call the callback to refresh the UI
      onScanComplete();

      // Show success message only if context is still mounted
      if (wasContextMounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra registrada com sucesso!')),
        );
      }
    } catch (e) {
      _logger.error('Error scanning receipt: $e');

      // Close dialog if it's still open
      if (isDialogOpen && context.mounted && !dialogCompleted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Check if context is still mounted before showing error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar compra: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _processReceiptUrl(String url) async {
    if (!context.mounted) return;

    // Show a loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Processando recibo...'),
          ],
        ),
        duration: Duration(
          seconds: 30,
        ), // Long duration, we'll dismiss it manually
      ),
    );

    try {
      // First check if receipt already exists in database
      final hasReceipt = await _receiptDb.hasReceipt(url);

      if (!context.mounted) return;

      if (hasReceipt) {
        // Hide the loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        // Show error message
        _showToast(
          'Este recibo já foi processado anteriormente.',
          Colors.orange,
        );
        return;
      }

      // Make API request using ApiService
      final responseData = await ApiService.post('receipt/scan', {'url': url});

      if (!context.mounted) return;

      // Extract receipt data
      final receiptData = responseData['receipt'];
      final items = responseData['items'] as List;

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

      // Update snackbar to show we're saving data
      if (context.mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Salvando dados...'),
              ],
            ),
            duration: Duration(
              seconds: 30,
            ), // Long duration, we'll dismiss it manually
          ),
        );
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

      // Hide the loading indicator
      scaffoldMessenger.hideCurrentSnackBar();

      // Show a simple toast notification of success
      _showToast(
        'Recibo processado com sucesso. ${items.length} itens adicionados.',
        Colors.green,
      );
    } catch (e) {
      if (!context.mounted) return;

      // Hide the loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message with details
      _showToast(
        'Erro: Falha ao processar recibo. ${e.toString()}',
        Colors.red,
      );

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

  // Helper method to show toast messages
  void _showToast(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
