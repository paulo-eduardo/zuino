import 'package:hive/hive.dart';
import 'package:zuino/utils/logger.dart';

class CategoriesDatabase {
  static final CategoriesDatabase _instance = CategoriesDatabase._internal();
  factory CategoriesDatabase() => _instance;
  final Logger _logger = Logger('CategoriesDatabase');

  // Default categories
  static const List<String> defaultCategories = [
    'Essenciais',
    'Hortifruti',
    'Limpeza e Higiene',
    'Guloseimas',
    'Bazar',
    'Bebidas',
    'Outros',
  ];

  CategoriesDatabase._internal() {
    // Initialize default categories when the database is created
    _initializeDefaultCategories();
  }

  // Initialize default categories if they don't exist
  Future<void> _initializeDefaultCategories() async {
    try {
      final box = await Hive.openBox('categories');

      // Only initialize if the box is empty
      if (box.isEmpty) {
        _logger.info('Initializing default categories');

        // Add each default category
        for (final category in defaultCategories) {
          await box.add(category);
        }
      }
    } catch (e) {
      _logger.error('Error initializing default categories: $e');
    }
  }

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
