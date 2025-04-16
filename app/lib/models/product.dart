class Product {
  final String code;
  final String name;
  final double lastUnitPrice;
  final String unit;
  final String category;

  Product({
    required this.code,
    required this.name,
    this.lastUnitPrice = 0.0,
    this.unit = 'un',
    this.category = 'Other',
  });

  // Create from Map (for database retrieval)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      code: map['code'] ?? '',
      name: map['name'] ?? 'Unknown Product',
      lastUnitPrice: (map['lastUnitPrice'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'un',
      category: map['category'] ?? 'Other',
    );
  }

  // Convert to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'lastUnitPrice': lastUnitPrice,
      'unit': unit,
      'category': category,
    };
  }

  // Create a copy with some fields changed
  Product copyWith({
    String? code,
    String? name,
    double? lastUnitPrice,
    String? unit,
    String? category,
  }) {
    return Product(
      code: code ?? this.code,
      name: name ?? this.name,
      lastUnitPrice: lastUnitPrice ?? this.lastUnitPrice,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'Product{code: $code, name: $name, price: $lastUnitPrice, unit: $unit, category: $category}';
  }
}
