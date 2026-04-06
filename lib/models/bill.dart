import 'order_item.dart';

enum PaymentMode { cash, upi, card }

class Bill {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double totalTax;
  final double grandTotal;
  final PaymentMode paymentMode;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;

  Bill({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
    required this.grandTotal,
    required this.paymentMode,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'cgst': cgst,
    'sgst': sgst,
    'totalTax': totalTax,
    'grandTotal': grandTotal,
    'paymentMode': paymentMode.name,
    'createdAt': createdAt.toIso8601String(),
    'customerName': customerName,
    'customerPhone': customerPhone,
    'userId': userId,
  };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'],
    items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    subtotal: (json['subtotal'] as num).toDouble(),
    cgst: (json['cgst'] as num).toDouble(),
    sgst: (json['sgst'] as num).toDouble(),
    totalTax: (json['totalTax'] as num).toDouble(),
    grandTotal: (json['grandTotal'] as num).toDouble(),
    paymentMode: PaymentMode.values.byName(json['paymentMode']),
    createdAt: DateTime.parse(json['createdAt']),
    customerName: json['customerName'],
    customerPhone: json['customerPhone'],
    userId: json['userId'],
  );
}
