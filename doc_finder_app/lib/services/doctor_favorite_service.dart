import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';

class DoctorFavoriteService {
  final AuthService _authService = AuthService();

  /// Get all favorite doctors for the current user
  Future<Map<String, dynamic>> getFavorites({int page = 1, int perPage = 15}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      final response = await _authService.authenticatedRequest(
        'GET',
        '/doctor-favorites?page=$page&per_page=$perPage',
      );

      print('Favorites response status: ${response.statusCode}');
      print('Favorites response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Favorites error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Add a doctor to favorites
  Future<Map<String, dynamic>> addToFavorites(int doctorId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/doctor-favorites',
        body: {'doctor_id': doctorId},
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add to favorites');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Remove a doctor from favorites
  Future<Map<String, dynamic>> removeFromFavorites(int doctorId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'DELETE',
        '/doctor-favorites/$doctorId',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to remove from favorites');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if a doctor is favorited
  Future<bool> isFavorited(int doctorId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/doctor-favorites/$doctorId/check',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_favorited'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status (add if not favorited, remove if favorited)
  Future<Map<String, dynamic>> toggleFavorite(int doctorId) async {
    try {
      final response = await _authService.authenticatedRequest(
        'POST',
        '/doctor-favorites/toggle',
        body: {'doctor_id': doctorId},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to toggle favorite');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}