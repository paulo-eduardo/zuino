import 'package:hive/hive.dart';
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
      _logger.info('Saved product: ${product.name} (${product.code})');
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
      _logger.info('Deleted product: $code');
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
      _logger.info('Batch saved ${products.length} products');
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
        _logger.info('Product not found in database: $code');
        return null;
      }

      _logger.info('Retrieved product from database: $code');
      return Product.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      _logger.error('Error getting product: $e');
      throw Exception('Failed to get product: $e');
    }
  }

  /// Gets all products
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
      result.sort((a, b) => a.name.compareTo(b.name));
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
        }
      }

      _logger.info('Calculated total price: $total');
      return total;
    } catch (e) {
      _logger.error('Error calculating total price', e);
      return 0.0;
    }
  }
}
