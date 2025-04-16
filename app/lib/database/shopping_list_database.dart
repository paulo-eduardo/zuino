import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/utils/logger.dart';

class ShoppingListDatabase {
  final _logger = Logger('ShoppingListDatabase');
  final String _boxName = 'shopping_list';

  // Get a ValueListenable for the shopping list box
  Future<ValueListenable<Box<dynamic>>> getListenable() async {
    try {
      // Make sure the box is open before getting the listenable
      final box = await Hive.openBox(_boxName);
      return box.listenable();
    } catch (e) {
      _logger.error('Error getting shopping list listenable', e);
      rethrow; // Using rethrow instead of throw e
    }
  }

  // Get all shopping list items
  Future<List<ShoppingItem>> getAllItems() async {
    try {
      final box = await Hive.openBox(_boxName);
      final items = <ShoppingItem>[];

      _logger.info(
        'Getting all shopping list items, box keys: ${box.keys.toList()}',
      );

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          try {
            // Handle both Map and non-Map data formats
            if (data is Map) {
              // If it's already a Map, use it directly
              final item = ShoppingItem.fromMap(
                Map<String, dynamic>.from(data),
              );
              items.add(item);
              _logger.info(
                'Retrieved shopping item: ${item.productCode}, quantity: ${item.quantity}',
              );
            } else {
              // If it's not a Map, create a simple item with the key as the product code
              final item = ShoppingItem(
                productCode: key.toString(),
                quantity: 1.0,
              );
              items.add(item);
              _logger.info(
                'Retrieved legacy shopping item: ${item.productCode}',
              );

              // Optionally, update the item in the database to the new format
              await box.put(key, item.toMap());
            }
          } catch (e, stackTrace) {
            _logger.error(
              'Error parsing shopping item with key $key: $e',
              e,
              stackTrace,
            );

            // Try to recover by creating a simple item with the key as the product code
            try {
              final item = ShoppingItem(
                productCode: key.toString(),
                quantity: 1.0,
              );
              items.add(item);
              _logger.info('Recovered shopping item: ${item.productCode}');

              // Update the item in the database to the new format
              await box.put(key, item.toMap());
            } catch (e2) {
              _logger.error(
                'Failed to recover shopping item with key $key: $e2',
              );
            }
          }
        } else {
          _logger.info('Null data found for key: $key');
        }
      }

      _logger.info('Retrieved ${items.length} shopping list items');
      return items;
    } catch (e, stackTrace) {
      _logger.error('Error getting all items', e, stackTrace);
      throw Exception('Failed to get all items: $e');
    }
  }

  // Add or update a shopping list item
  Future<void> addOrUpdateItem(ShoppingItem item) async {
    try {
      final box = await Hive.openBox(_boxName);
      _logger.info(
        'Adding/updating item in shopping list: ${item.productCode}',
      );
      await box.put(item.productCode, item.toMap());
    } catch (e) {
      _logger.error('Error adding/updating item: ${item.productCode}', e);
      throw Exception('Failed to add/update item: $e');
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
      _logger.info('Removed item $productCode from shopping list');
    } catch (e) {
      _logger.error('Error removing item: $productCode', e);
      rethrow;
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
      rethrow;
    }
  }

  // Increment the quantity of a shopping list item
  Future<void> incrementQuantity(String productCode, double amount) async {
    try {
      final box = await Hive.openBox(_boxName);
      final item = box.get(productCode);

      if (item != null && item is Map) {
        final currentQuantity = (item['quantity'] as num).toDouble();
        final newQuantity = currentQuantity + amount;

        if (newQuantity <= 0) {
          // If quantity is zero or negative, remove the item
          await removeItem(productCode);
        } else {
          // Otherwise update the quantity
          final updatedItem = Map<String, dynamic>.from(item);
          updatedItem['quantity'] = newQuantity;
          await box.put(productCode, updatedItem);
          _logger.info(
            'Updated quantity for item $productCode to $newQuantity',
          );
        }
      } else {
        throw Exception('Item not found in shopping list');
      }
    } catch (e) {
      _logger.error('Error updating quantity for item: $productCode', e);
      rethrow;
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
      rethrow;
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
