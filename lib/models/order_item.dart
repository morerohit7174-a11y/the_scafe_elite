// lib/models/order_item.dart
import 'product.dart';

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'product':  product.toJson(),
    'quantity': quantity,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    product:  Product.fromJson(json['product'] as Map<String, dynamic>),
    quantity: (json['quantity'] as num).toInt(),
  );
}
