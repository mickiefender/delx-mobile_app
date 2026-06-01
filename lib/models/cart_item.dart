import 'package:delx/models/product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;
  final DateTime createdAt;
  DateTime updatedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalPrice => product.price * quantity;
  
  /// Unit price of the product (alias for product.price)
  double get unitPrice => product.price;

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product.toJson(),
    'quantity': quantity,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

factory CartItem.fromJson(Map<String, dynamic> json) {
    // Safe quantity parsing - handle null values
    int itemQuantity;
    final quantityValue = json['quantity'];
    if (quantityValue is int) {
      itemQuantity = quantityValue;
    } else if (quantityValue is num) {
      itemQuantity = quantityValue.toInt();
    } else {
      itemQuantity = 1; // Default to 1 if quantity is null/invalid
    }

    return CartItem(
      id: json['id'] is String 
          ? json['id'] as String 
          : '',
      product: Product.fromJson(json['product'] is Map<String, dynamic>
          ? json['product'] as Map<String, dynamic>
          : <String, dynamic>{}),
      quantity: itemQuantity,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CartItem(
    id: id ?? this.id,
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
