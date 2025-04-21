import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/models/product.dart';
import 'package:zuino/models/shopping_item.dart';

class ProductDatabase {
  final _logger = Logger('ProductDatabase');
  final String _boxName = 'products';

  /// Inserts or updates a single product
  Future<void> insertOrUpdate(Product product) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(product.code, product.toMap());
    } catch (e) {
      _logger.error('Error saving product: $e');
      throw Exception('Failed to save product: $e');
    }
  }

  /// Deletes a product by its code
  Future<void> delete(String code) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(code);
    } catch (e) {
      _logger.error('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Batch inserts or updates multiple products at once
  /// Optimized for receipt processing
  Future<void> batchInsertOrUpdate(List<Product> products) async {
    try {
      final box = await Hive.openBox(_boxName);

      // Convert products to a map for batch operation
      final Map<String, Map<String, dynamic>> batch = {};
      for (final product in products) {
        batch[product.code] = product.toMap();
      }

      // Perform batch operation
      await box.putAll(batch);
    } catch (e) {
      _logger.error('Error in batch save: $e');
      throw Exception('Failed to save products in batch: $e');
    }
  }

  /// Gets a product by code
  Future<Product?> getProduct(String code) async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get(code);

      if (data == null) {
        return null;
      }

      return Product.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      _logger.error('Error getting product: $e');
      throw Exception('Failed to get product: $e');
    }
  }

  /// Gets all products sorted by name
  Future<List<Product>> getAllProducts() async {
    try {
      final box = await Hive.openBox(_boxName);
      final List<Product> result = [];

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final product = Product.fromMap(Map<String, dynamic>.from(data));
          result.add(product);
        }
      }

      // Sort by name for consistent display
      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return result;
    } catch (e) {
      _logger.error('Error getting all products: $e');
      throw Exception('Failed to get all products: $e');
    }
  }

  /// Calculates the total price of a list of shopping items
  Future<double> calculateTotalPrice(List<ShoppingItem> items) async {
    double total = 0.0;

    try {
      for (final item in items) {
        final product = await getProduct(item.productCode);

        if (product != null) {
          total += product.lastUnitPrice * item.quantity;
        } else {
          _logger.warning('Product not found for code: ${item.productCode}');
        }
      }

      return total;
    } catch (e) {
      _logger.error('Error calculating total price', e);
      return 0.0;
    }
  }

  /// Clears all products from the database
  Future<void> clearAll() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.clear();
    } catch (e, stackTrace) {
      _logger.error('Error clearing products database', e, stackTrace);
      rethrow;
    }
  }

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

  /// Gets products filtered by name
  /// Returns a list of products whose names contain the given search string
  Future<List<Product>> getProductsByName(String searchString) async {
    try {
      // First get all products
      final allProducts = await getAllProducts();

      // If search string is empty, return all products
      if (searchString.trim().isEmpty) {
        return allProducts;
      }

      // Filter products by name (case-insensitive)
      final normalizedSearch = searchString.toLowerCase().trim();
      final filteredProducts =
          allProducts
              .where(
                (product) =>
                    product.name.toLowerCase().contains(normalizedSearch),
              )
              .toList();

      return filteredProducts;
    } catch (e) {
      _logger.error('Error filtering products by name: $e');
      throw Exception('Failed to filter products by name: $e');
    }
  }
}
