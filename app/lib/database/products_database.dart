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
}
