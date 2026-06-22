import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double kFreeDeliveryThreshold = 2000;
const double kStandardDeliveryFee   = 200;
const double kExpressDeliveryFee    = 500;

enum DeliveryOption { standard, express, pickup }

String deliveryOptionToString(DeliveryOption o) =>
    o == DeliveryOption.express ? 'express' :
    o == DeliveryOption.pickup  ? 'pickup'  : 'standard';

DeliveryOption deliveryOptionFromString(String? s) =>
    s == 'express' ? DeliveryOption.express :
    s == 'pickup'  ? DeliveryOption.pickup  : DeliveryOption.standard;

class LocalCartItem {
  final String id;          // "med-{id}" or "prod-{id}"
  final String type;        // "medicine" | "product"
  final String name;
  final double price;
  final String? image;
  final String? strength;
  final String? form;
  final String? category;
  int quantity;

  LocalCartItem({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    this.image,
    this.strength,
    this.form,
    this.category,
    this.quantity = 1,
  });

  factory LocalCartItem.fromJson(Map<String, dynamic> j) => LocalCartItem(
        id: j['id'] ?? '',
        type: j['type'] ?? 'medicine',
        name: j['name'] ?? '',
        price: (j['price'] is num) ? (j['price'] as num).toDouble() : 0.0,
        image: j['image'],
        strength: j['strength'],
        form: j['form'],
        category: j['category'],
        quantity: j['quantity'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'price': price,
        'image': image,
        'strength': strength,
        'form': form,
        'category': category,
        'quantity': quantity,
      };

  double get subtotal => price * quantity;
}

class OrderDetails {
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String notes;

  OrderDetails({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    required this.notes,
  });
}

/// Local cart singleton with ChangeNotifier — mirrors the web `CartContext`.
/// Persists items in SharedPreferences under `xyvra_cart`.
class LocalCartService extends ChangeNotifier {
  LocalCartService._();
  static final LocalCartService instance = LocalCartService._();

  static const _storageKey = 'xyvra_cart';
  static const _deliveryKey = 'xyvra_cart_delivery';

  final List<LocalCartItem> _items = [];
  DeliveryOption _deliveryOption = DeliveryOption.standard;
  OrderDetails? _orderDetails;
  bool _initialized = false;

  List<LocalCartItem> get items => List.unmodifiable(_items);
  DeliveryOption get deliveryOption => _deliveryOption;
  OrderDetails? get orderDetails => _orderDetails;

  int get cartCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get cartTotal => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  double get deliveryFee {
    if (_deliveryOption == DeliveryOption.pickup) return 0;
    if (_deliveryOption == DeliveryOption.express) return kExpressDeliveryFee;
    return cartTotal >= kFreeDeliveryThreshold ? 0 : kStandardDeliveryFee;
  }

  double get grandTotal => cartTotal + deliveryFee;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.clear();
          _items.addAll(decoded.map((e) => LocalCartItem.fromJson(Map<String, dynamic>.from(e))));
        }
      }
      final dlv = prefs.getString(_deliveryKey);
      if (dlv != null) _deliveryOption = deliveryOptionFromString(dlv);
    } catch (_) {/* ignore */}
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_items.map((i) => i.toJson()).toList()));
      await prefs.setString(_deliveryKey, deliveryOptionToString(_deliveryOption));
    } catch (_) {/* ignore */}
  }

  void addItem(LocalCartItem newItem) {
    final existing = _items.indexWhere((i) => i.id == newItem.id);
    if (existing >= 0) {
      _items[existing].quantity += 1;
    } else {
      _items.add(newItem);
    }
    _persist();
    notifyListeners();
  }

  void updateQuantity(String id, int qty) {
    if (qty <= 0) {
      removeItem(id);
      return;
    }
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].quantity = qty;
      _persist();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _persist();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _orderDetails = null;
    _persist();
    notifyListeners();
  }

  void setDeliveryOption(DeliveryOption o) {
    _deliveryOption = o;
    _persist();
    notifyListeners();
  }

  void setOrderDetails(OrderDetails d) {
    _orderDetails = d;
    notifyListeners();
  }
}
