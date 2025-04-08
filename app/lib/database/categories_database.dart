import 'package:hive/hive.dart';

class CategoriesDatabase {
  static final CategoriesDatabase _instance = CategoriesDatabase._internal();
  factory CategoriesDatabase() => _instance;

  CategoriesDatabase._internal();

  // Get all categories
  Future<List<String>> getCategories() async {
    final box = await Hive.openBox('categories');
    final List<String> categories = List<String>.from(box.values.toList());

    // Sort categories alphabetically
    categories.sort();

    return categories;
  }

  // Add a new category if it doesn't exist
  Future<void> addCategory(String category) async {
    if (category.trim().isEmpty) return;

    final box = await Hive.openBox('categories');
    final categories = await getCategories();

    // Only add if it doesn't already exist
    if (!categories.contains(category.trim())) {
      await box.add(category.trim());
    }
  }
}
