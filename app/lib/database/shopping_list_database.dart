import 'package:hive/hive.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/utils/logger.dart';

class ShoppingListDatabase {
  final _logger = Logger('ShoppingListDatabase');
  final String _boxName = 'shopping_list';

  // Get all shopping list items
  Future<List<ShoppingItem>> getAllItems() async {
    try {
      final box = await Hive.openBox(_boxName);
      final items = <ShoppingItem>[];

      for (var key in box.keys) {
        final item = box.get(key);
        if (item != null && item is Map) {
          try {
            items.add(ShoppingItem.fromMap(Map<String, dynamic>.from(item)));
          } catch (e) {
            _logger.error('Error parsing shopping item: $item', e);
          }
        }
      }

      _logger.info('Retrieved ${items.length} shopping list items');
      return items;
    } catch (e) {
      _logger.error('Error getting shopping list items', e);
      return [];
    }
  }

  // Add or update a shopping list item
  Future<void> addOrUpdateItem(ShoppingItem item) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(item.productCode, item.toMap());
      _logger.info('Added/updated shopping item: ${item.productCode}');
    } catch (e) {
      _logger.error('Error adding/updating shopping item', e);
      throw e;
    }
  }

  // Get a specific shopping list item by product code
  Future<ShoppingItem?> getItem(String productCode) async {
    try {
      final box = await Hive.openBox(_boxName);
      final item = box.get(productCode);

      if (item != null && item is Map) {
        return ShoppingItem.fromMap(Map<String, dynamic>.from(item));
      }
      return null;
    } catch (e) {
      _logger.error('Error getting shopping item: $productCode', e);
      return null;
    }
  }

  // Remove a shopping list item
  Future<void> removeItem(String productCode) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(productCode);
      _logger.info('Removed shopping item: $productCode');
    } catch (e) {
      _logger.error('Error removing shopping item: $productCode', e);
      throw e;
    }
  }

  // Update the quantity of a shopping list item
  Future<void> updateQuantity(String productCode, double quantity) async {
    try {
      final box = await Hive.openBox(_boxName);
      final item = box.get(productCode);

      if (item != null && item is Map) {
        final updatedItem = Map<String, dynamic>.from(item);
        updatedItem['quantity'] = quantity;
        await box.put(productCode, updatedItem);
        _logger.info('Updated quantity for item $productCode to $quantity');
      } else {
        throw Exception('Item not found in shopping list');
      }
    } catch (e) {
      _logger.error('Error updating quantity for item: $productCode', e);
      throw e;
    }
  }

  // Clear all shopping list items
  Future<void> clearAll() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.clear();
      _logger.info('Cleared all shopping list items');
    } catch (e) {
      _logger.error('Error clearing shopping list', e);
      throw e;
    }
  }

  // Check if an item exists in the shopping list
  Future<bool> itemExists(String productCode) async {
    try {
      final box = await Hive.openBox(_boxName);
      return box.containsKey(productCode);
    } catch (e) {
      _logger.error('Error checking if item exists: $productCode', e);
      return false;
    }
  }

  // Get the count of items in the shopping list
  Future<int> getItemCount() async {
    try {
      final box = await Hive.openBox(_boxName);
      return box.length;
    } catch (e) {
      _logger.error('Error getting item count', e);
      return 0;
    }
  }
}
