class ShoppingItem {
  final String productCode;
  final double quantity;

  ShoppingItem({required this.productCode, this.quantity = 1.0});

  // Create from Map (for database retrieval)
  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      productCode: map['productCode'] as String,
      quantity: (map['quantity'] as num).toDouble(),
    );
  }

  // Convert to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {'productCode': productCode, 'quantity': quantity};
  }

  // Create a copy with some fields changed
  ShoppingItem copyWith({String? productCode, double? quantity}) {
    return ShoppingItem(
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(productCode: $productCode, quantity: $quantity)';
  }
}
