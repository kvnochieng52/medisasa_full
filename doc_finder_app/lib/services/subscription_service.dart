import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/auth_service.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();

  Future<bool> hasActiveSubscription() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/subscription/status',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['has_active_subscription'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/subscription/details',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Initiates a DPO Pay transaction.
  /// Returns { success, message, data: { payment_url, trans_token, company_ref } }
  Future<Map<String, dynamic>> processPayment({
    required String plan,
    required String paymentMethod,
    Map<String, dynamic> paymentDetails = const {},
  }) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/subscription/payment',
        body: {
          'plan': plan,
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Payment initiated',
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to initiate payment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while initiating payment',
      };
    }
  }

  /// Polls DPO to check if the payment for [transToken] has been confirmed.
  /// Returns { success, data: { status, message } }
  Future<Map<String, dynamic>> verifyPayment(String transToken) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/subscription/verify-payment/$transToken',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'status': data['data']['status'],
          'message': data['data']['message'] ?? '',
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Payment verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': 'Error verifying payment status',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/subscription/plans',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['plans'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/subscription/cancel',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Subscription cancelled successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to cancel subscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while cancelling subscription',
      };
    }
  }
}
