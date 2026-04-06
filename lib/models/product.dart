class Product {
  final String id;
  final String name;
  final String? nameHindi;
  final double price;
  final String category;
  final bool isAvailable;
  final String? size; // ✅ optional

  Product({
    required this.id,
    required this.name,
    this.nameHindi,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.size, // ✅ required काढलं
  });

  Product copyWith({
    String? id,
    String? name,
    String? nameHindi,
    double? price,
    String? category,
    bool? isAvailable,
    String? size, // ✅ add केलं
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      nameHindi: nameHindi ?? this.nameHindi,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      size: size ?? this.size, // ✅ fix
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameHindi': nameHindi,
        'price': price,
        'category': category,
        'isAvailable': isAvailable,
        'size': size, // ✅ important
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        nameHindi: json['nameHindi'],
        price: (json['price'] as num).toDouble(),
        category: json['category'],
        isAvailable: json['isAvailable'] ?? true,
        size: json['size'] ?? '', // ✅ crash safe
      );
}