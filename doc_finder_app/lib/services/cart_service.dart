import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine/cart_model.dart';
import '../models/api_config.dart';

class CartService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get cart items
  static Future<CartResponse> getCart() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return CartResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch cart');
        }
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cart: $e');
    }
  }

  // Add item to cart
  static Future<CartItem> addToCart({
    required int medicineId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: await _getHeaders(),
        body: json.encode({
          'medicine_id': medicineId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          return CartItem.fromJson(data['cart_item']);
        } else {
          throw Exception(data['message'] ?? 'Failed to add item to cart');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to add item to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding item to cart: $e');
    }
  }

  // Update cart item quantity
  static Future<CartItem> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/$cartItemId'),
        headers: await _getHeaders(),
        body: json.encode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return CartItem.fromJson(data['cart_item']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update cart item');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to update cart item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  static Future<void> removeFromCart(int cartItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$cartItemId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message'] ?? 'Failed to remove item from cart');
        }
      } else {
        throw Exception('Failed to remove item from cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }

  // Clear entire cart
  static Future<void> clearCart() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message'] ?? 'Failed to clear cart');
        }
      } else {
        throw Exception('Failed to clear cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }

  // Get cart summary
  static Future<CartSummary> getCartSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart/summary'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return CartSummary.fromJson(data['summary']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch cart summary');
        }
      } else {
        throw Exception('Failed to fetch cart summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cart summary: $e');
    }
  }

  // Quick add to cart with error handling
  static Future<Map<String, dynamic>> quickAddToCart({
    required int medicineId,
    int quantity = 1,
  }) async {
    try {
      final cartItem = await addToCart(
        medicineId: medicineId,
        quantity: quantity,
      );

      final summary = await getCartSummary();

      return {
        'success': true,
        'cart_item': cartItem,
        'summary': summary,
        'message': 'Item added to cart successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Check if medicine is already in cart
  static Future<bool> isMedicineInCart(int medicineId) async {
    try {
      final cartResponse = await getCart();
      return cartResponse.cartItems.any((item) => item.medicineId == medicineId);
    } catch (e) {
      return false;
    }
  }

  // Get cart item for specific medicine
  static Future<CartItem?> getCartItemForMedicine(int medicineId) async {
    try {
      final cartResponse = await getCart();
      final cartItems = cartResponse.cartItems.where((item) => item.medicineId == medicineId);
      return cartItems.isNotEmpty ? cartItems.first : null;
    } catch (e) {
      return null;
    }
  }

  // Update or add medicine to cart
  static Future<Map<String, dynamic>> updateOrAddToCart({
    required int medicineId,
    required int quantity,
  }) async {
    try {
      final existingItem = await getCartItemForMedicine(medicineId);
      
      late CartItem cartItem;
      String message;

      if (existingItem != null) {
        // Update existing item
        cartItem = await updateCartItem(
          cartItemId: existingItem.id,
          quantity: quantity,
        );
        message = 'Cart item updated successfully';
      } else {
        // Add new item
        cartItem = await addToCart(
          medicineId: medicineId,
          quantity: quantity,
        );
        message = 'Item added to cart successfully';
      }

      final summary = await getCartSummary();

      return {
        'success': true,
        'cart_item': cartItem,
        'summary': summary,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}