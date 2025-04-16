import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zuino/utils/logger.dart';

class InventoryDatabase {
  static final InventoryDatabase _instance = InventoryDatabase._internal();
  factory InventoryDatabase() => _instance;
  final _logger = Logger('InventoryDatabase');

  InventoryDatabase._internal();

  // Helper method to open the box
  Future<Box> _openBox() async {
    return await Hive.openBox('inventory');
  }

  // Insert or update an inventory item
  Future<void> insertOrUpdateItem(Map<String, dynamic> item) async {
    try {
      // Create a new map with all the values to ensure proper typing
      final Map<String, dynamic> cleanItem = {};

      // Copy all fields with explicit typing
      item.forEach((key, value) {
        cleanItem[key] = value;
      });

      // Make sure 'codigo' exists and is a string
      if (!cleanItem.containsKey('codigo') || cleanItem['codigo'] == null) {
        throw Exception('Inventory item must have a valid codigo');
      }

      // Ensure stock is a double
      if (cleanItem.containsKey('stock')) {
        cleanItem['stock'] = double.parse(cleanItem['stock'].toString());
      } else {
        cleanItem['stock'] = 0.0;
      }

      // Open box and store the item directly
      final box = await Hive.openBox('inventory');
      await box.put(cleanItem['codigo'].toString(), cleanItem);
      _logger.info('Item ${cleanItem['codigo']} saved to inventory');
    } catch (e) {
      _logger.error('Error in insertOrUpdateItem: $e');
      rethrow; // Rethrow to allow caller to handle it
    }
  }

  // Get all inventory items
  Future<List<Map<String, dynamic>>> getInventory() async {
    final box = await _openBox();
    final items = box.values.toList();

    // Convert to properly typed maps
    final List<Map<String, dynamic>> typedItems = [];
    for (final item in items) {
      if (item is Map) {
        final Map<String, dynamic> typedItem = {};
        item.forEach((key, value) {
          typedItem[key.toString()] = value;
        });
        typedItems.add(typedItem);
      }
    }

    return typedItems;
  }

  // Add stock to an inventory item
  Future<void> addStock(String codigo, double amount) async {
    final box = await Hive.openBox('inventory');
    final item = box.get(codigo);

    if (item != null) {
      // Update existing item
      item['stock'] = (item['stock'] ?? 0.0) + amount;
      await box.put(codigo, item);
      _logger.info('Added $amount to stock of item $codigo');
    } else {
      throw Exception('Item not found in inventory.');
    }
  }

  // Remove stock from an inventory item (use/spend)
  Future<void> removeStock(String codigo, double amount) async {
    final box = await Hive.openBox('inventory');
    final item = box.get(codigo);

    if (item != null) {
      final currentStock = (item['stock'] ?? 0.0) as double;

      if (currentStock >= amount) {
        item['stock'] = currentStock - amount;
        await box.put(codigo, item);
        _logger.info('Removed $amount from stock of item $codigo');
      } else {
        throw Exception('Not enough stock available.');
      }
    } else {
      throw Exception('Item not found in inventory.');
    }
  }

  // Delete an inventory item
  Future<void> removeItem(String codigo) async {
    final box = await Hive.openBox('inventory');
    await box.delete(codigo);
    _logger.info('Item $codigo removed from inventory');
  }

  // Get items that are out of stock
  Future<List<Map<String, dynamic>>> getOutOfStockItems() async {
    final box = await Hive.openBox('inventory');
    final items = box.values.toList();

    List<Map<String, dynamic>> result = [];
    for (var item in items) {
      // Convert each item to Map<String, dynamic>
      Map<String, dynamic> typedItem = Map<String, dynamic>.from(item);
      final stock = (typedItem['stock'] ?? 0.0) as double;

      if (stock <= 0) {
        result.add(typedItem);
      }
    }

    return result;
  }

  // Update inventory from receipt items
  Future<void> updateFromReceipt(List<Map<String, dynamic>> items) async {
    final box = await Hive.openBox('inventory');

    for (var item in items) {
      try {
        final codigo = item['codigo'];
        final name = item['name'] ?? 'Unknown Product';
        final unit = item['unit'] ?? 'UN';
        final category = item['category'] ?? 'Outros';

        // Get numeric values safely
        final double quantity = _safeParseDouble(item['stock']);
        final double unitValue = _safeParseDouble(item['lastUnitValue']);

        final existingItem = box.get(codigo);

        if (existingItem != null) {
          // Update existing inventory item
          final double currentStock = _safeParseDouble(existingItem['stock']);
          existingItem['stock'] = currentStock + quantity;
          existingItem['lastUnitValue'] = unitValue;
          await box.put(codigo, existingItem);
          _logger.info(
            'Updated item $codigo from receipt. New stock: ${existingItem['stock']}',
          );
        } else {
          // Add new inventory item
          await box.put(codigo, {
            'codigo': codigo,
            'name': name,
            'unit': unit,
            'stock': quantity,
            'category': category,
            'lastUnitValue': unitValue,
          });
          _logger.info(
            'Added new item $codigo from receipt with stock: $quantity',
          );
        }
      } catch (e) {
        _logger.error(
          'Error updating inventory item: ${item['codigo'] ?? 'unknown'} - $e',
        );
        // Continue with next item
      }
    }
  }

  // Get a specific inventory item by code
  Future<Map<String, dynamic>?> getItemByCode(String codigo) async {
    final box = await Hive.openBox('inventory');
    final item = box.get(codigo);

    if (item != null) {
      return Map<String, dynamic>.from(item);
    }

    return null;
  }

  // Update category for an inventory item
  Future<void> updateCategory(String codigo, String category) async {
    final box = await Hive.openBox('inventory');
    final item = box.get(codigo);

    if (item != null) {
      item['category'] = category;
      await box.put(codigo, item);
      _logger.info('Updated category of item $codigo to $category');
    } else {
      throw Exception('Item not found in inventory.');
    }
  }

  // Get multiple inventory items by their codes
  Future<Map<String, Map<String, dynamic>>> getItemsByCodes(
    List<String> codes,
  ) async {
    final box = await Hive.openBox('inventory');
    final Map<String, Map<String, dynamic>> result = {};

    for (final code in codes) {
      final item = box.get(code);
      if (item != null) {
        result[code] = Map<String, dynamic>.from(item);
      }
    }

    return result;
  }

  // Helper method for safe parsing
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    try {
      return double.parse(value.toString());
    } catch (e) {
      return 0.0;
    }
  }

  // Get items that have stock available (stock > 0)
  Future<List<Map<String, dynamic>>> getInStockItems() async {
    final box = await Hive.openBox('inventory');
    final items = box.values.toList();

    List<Map<String, dynamic>> result = [];
    for (var item in items) {
      // Convert each item to Map<String, dynamic>
      Map<String, dynamic> typedItem = Map<String, dynamic>.from(item);
      final stock = (typedItem['stock'] ?? 0.0) as double;

      if (stock > 0) {
        result.add(typedItem);
      }
    }

    return result;
  }
}
