import 'package:hive/hive.dart';
import 'package:zuino/utils/logger.dart';

class ReceiptsDatabase {
  static final ReceiptsDatabase _instance = ReceiptsDatabase._internal();
  factory ReceiptsDatabase() => _instance;
  final _logger = Logger('ReceiptsDatabase');

  ReceiptsDatabase._internal();

  Future<Box> _openBox() async {
    return await Hive.openBox('receipts');
  }

  Future<void> saveReceipt({
    required String url,
    required Map<String, dynamic> store,
    required DateTime date,
    required double totalAmount,
    required String? paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final box = await _openBox();

      // Format receipt data
      final receiptData = {
        'url': url,
        'store': store,
        'date': date.millisecondsSinceEpoch,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod ?? 'Unknown',
        'items': items,
      };

      // Save receipt using URL as the key
      await box.put(url, receiptData);
      _logger.info('Receipt saved successfully for URL: $url');
    } catch (e) {
      _logger.error('Error saving receipt: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReceipts() async {
    try {
      final box = await _openBox();
      final receipts = box.values.toList();

      return receipts.map((receipt) {
        return Map<String, dynamic>.from(receipt);
      }).toList();
    } catch (e) {
      _logger.error('Error getting receipts: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReceiptsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final box = await _openBox();
      final receipts = box.values.toList();

      final startMillis = startDate.millisecondsSinceEpoch;
      final endMillis = endDate.millisecondsSinceEpoch;

      return receipts
          .where((receipt) {
            final receiptDate = receipt['date'] as int;
            return receiptDate >= startMillis && receiptDate <= endMillis;
          })
          .map((receipt) {
            return Map<String, dynamic>.from(receipt);
          })
          .toList();
    } catch (e) {
      _logger.error('Error getting receipts by date range: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getReceiptByUrl(String url) async {
    try {
      final box = await _openBox();
      final receipt = box.get(url);

      if (receipt != null) {
        return Map<String, dynamic>.from(receipt);
      }

      return null;
    } catch (e) {
      _logger.error('Error getting receipt by URL: $e');
      rethrow;
    }
  }

  Future<void> deleteReceipt(String url) async {
    try {
      final box = await _openBox();
      await box.delete(url);
      _logger.info('Receipt with URL deleted successfully');
    } catch (e) {
      _logger.error('Error deleting receipt: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllReceiptItems() async {
    try {
      final receipts = await getReceipts();
      final List<Map<String, dynamic>> allItems = [];

      for (var receipt in receipts) {
        final items = List<Map<String, dynamic>>.from(receipt['items']);
        final date = DateTime.fromMillisecondsSinceEpoch(
          receipt['date'] as int,
        );
        final storeInfo = Map<String, dynamic>.from(receipt['store']);

        for (var item in items) {
          allItems.add({
            ...item,
            'receiptUrl': receipt['url'],
            'receiptDate': date,
            'storeName': storeInfo['name'] ?? 'Unknown Store',
          });
        }
      }

      return allItems;
    } catch (e) {
      _logger.error('Error getting all receipt items: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReceiptItemsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final receipts = await getReceiptsByDateRange(startDate, endDate);
      final List<Map<String, dynamic>> rangeItems = [];

      for (var receipt in receipts) {
        final items = List<Map<String, dynamic>>.from(receipt['items']);
        final date = DateTime.fromMillisecondsSinceEpoch(
          receipt['date'] as int,
        );
        final storeInfo = Map<String, dynamic>.from(receipt['store']);

        for (var item in items) {
          rangeItems.add({
            ...item,
            'receiptUrl': receipt['url'],
            'receiptDate': date,
            'storeName': storeInfo['name'] ?? 'Unknown Store',
          });
        }
      }

      return rangeItems;
    } catch (e) {
      _logger.error('Error getting receipt items by date range: $e');
      rethrow;
    }
  }

  Future<bool> hasReceipt(String url) async {
    try {
      final box = await _openBox();
      return box.containsKey(url);
    } catch (e) {
      _logger.error('Error checking if receipt exists: $e');
      rethrow;
    }
  }

  // Add this method to the ReceiptDatabase class

  Future<void> clearAll() async {
    try {
      final box = await _openBox();
      await box.clear();
      _logger.info('Cleared all receipts from database');
    } catch (e, stackTrace) {
      _logger.error('Error clearing receipts database', e, stackTrace);
      rethrow;
    }
  }
}
