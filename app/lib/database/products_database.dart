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
    final products = box.values.toList().cast<Map<String, dynamic>>();
    return products.where((product) {
      final quantity = product['quantity'] as double;
      final used = (product['used'] ?? 0.0) as double;
      return quantity <= used;
    }).toList();
  }
}
