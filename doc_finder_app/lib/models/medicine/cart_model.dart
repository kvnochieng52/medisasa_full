import 'medicine_model.dart';

class CartItem {
  final int id;
  final int userId;
  final int medicineId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Medicine? medicine;

  CartItem({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    this.medicine,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      medicineId: json['medicine_id'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unit_price'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      medicine: json['medicine'] != null
          ? Medicine.fromJson(json['medicine'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'medicine_id': medicineId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'medicine': medicine?.toJson(),
    };
  }

  // Helper getter for formatted unit price
  String get formattedUnitPrice => 'KSh ${unitPrice.toStringAsFixed(2)}';

  // Helper getter for formatted total price
  String get formattedTotalPrice => 'KSh ${totalPrice.toStringAsFixed(2)}';

  // Helper method to create a copy with updated quantity
  CartItem copyWith({
    int? id,
    int? userId,
    int? medicineId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    Medicine? medicine,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineId: medicineId ?? this.medicineId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? (quantity != null ? (quantity * this.unitPrice) : this.totalPrice),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicine: medicine ?? this.medicine,
    );
  }
}

class CartResponse {
  final List<CartItem> cartItems;
  final CartSummary summary;

  CartResponse({
    required this.cartItems,
    required this.summary,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cartItems: (json['cart_items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      summary: CartSummary.fromJson(json['summary']),
    );
  }
}

class CartSummary {
  final double totalAmount;
  final int itemCount;
  final int itemsInCart;

  CartSummary({
    required this.totalAmount,
    required this.itemCount,
    required this.itemsInCart,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      totalAmount: double.parse(json['total_amount'].toString()),
      itemCount: json['item_count'],
      itemsInCart: json['items_in_cart'],
    );
  }

  // Helper getter for formatted total amount
  String get formattedTotalAmount => 'KSh ${totalAmount.toStringAsFixed(2)}';

  // Helper getter for items summary text
  String get itemsSummaryText {
    if (itemsInCart == 0) return 'No items in cart';
    if (itemsInCart == 1) return '1 item';
    return '$itemsInCart items';
  }

  // Helper getter for quantity summary text
  String get quantitySummaryText {
    if (itemCount == 0) return 'No items';
    if (itemCount == 1) return '1 item';
    return '$itemCount items';
  }
}