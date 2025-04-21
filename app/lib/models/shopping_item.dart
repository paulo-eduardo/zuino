class ShoppingItem {
  final String productCode;
  final double quantity;
  final int? id; // New field for ordering

  ShoppingItem({required this.productCode, this.quantity = 1.0, this.id});

  // Create from Map (for database retrieval)
  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      productCode: map['productCode'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      id: map['id'] as int?, // Extract ID if present
    );
  }

  // Convert to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'productCode': productCode,
      'quantity': quantity,
      'id': id, // Include ID in the map
    };
  }

  // Create a copy with some fields changed
  ShoppingItem copyWith({String? productCode, double? quantity, int? id}) {
    return ShoppingItem(
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(productCode: $productCode, quantity: $quantity, id: $id)';
  }
}
