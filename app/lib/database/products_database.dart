import 'package:hive/hive.dart';

class ProductsDatabase {
  static final ProductsDatabase _instance = ProductsDatabase._internal();
  factory ProductsDatabase() => _instance;

  ProductsDatabase._internal();

  Future<void> insertOrUpdateProduct(Map<String, dynamic> product) async {
    final box = await Hive.openBox('products');
    await box.put(product['codigo'], product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final box = await Hive.openBox('products');
    return box.values.toList().cast<Map<String, dynamic>>();
  }

  Future<void> saveProducts(List<Map<String, dynamic>> productList) async {
    final box = await Hive.openBox('products');
    for (var product in productList) {
      if (!product.containsKey('codigo')) {
        continue;
      }
      final existingProduct = box.get(product['codigo']);
      if (existingProduct != null) {
        product['quantity'] += existingProduct['quantity'];
      }
      await box.put(product['codigo'], product);
    }
  }

  Future<void> useProduct(String codigo, double amount) async {
    final box = await Hive.openBox('products');
    final product = box.get(codigo);
    if (product != null) {
      final used = (product['used'] ?? 0) + amount;
      final availableStock = product['quantity'] - used;
      if (availableStock >= 0) {
        product['used'] = used;
        await box.put(codigo, product);
      } else {
        throw Exception('Not enough stock to use the requested amount.');
      }
    } else {
      throw Exception('Product not found.');
    }
  }
  
  Future<void> removeProduct(String codigo) async {
    final box = await Hive.openBox('products');
    await box.delete(codigo);
  }
  
  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final box = await Hive.openBox('products');
    final products = box.values.toList();
    
    List<Map<String, dynamic>> result = [];
    for (var item in products) {
      // Convert each item to Map<String, dynamic>
      Map<String, dynamic> product = Map<String, dynamic>.from(item);
      final quantity = product['quantity'] as double;
      final used = (product['used'] ?? 0.0) as double;
      
      if (quantity <= used) {
        result.add(product);
      }
    }
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getSortedProducts() async {
    final box = await Hive.openBox('products');
    final rawProducts = box.values.toList();
    
    // Properly convert each item to Map<String, dynamic>
    final List<Map<String, dynamic>> productsList = rawProducts.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
    
    // Sort products: first by stock availability, then by name
    productsList.sort((a, b) {
      // Calculate remaining stock for both products
      final aStock = (a['quantity'] as double) - (a['used'] as double? ?? 0.0);
      final bStock = (b['quantity'] as double) - (b['used'] as double? ?? 0.0);
      
      // If one has zero stock and the other doesn't, the one with stock comes first
      if (aStock <= 0 && bStock > 0) return 1;
      if (aStock > 0 && bStock <= 0) return -1;
      
      // If both have stock or both don't have stock, sort alphabetically by name
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    
    return productsList;
  }
}
