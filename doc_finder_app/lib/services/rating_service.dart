import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/models/api_config.dart';

class RatingService {
  final AuthService _authService = AuthService();

  /// Submit a rating for a doctor or facility
  Future<Map<String, dynamic>> submitRating({
    required String rateableType, // 'doctor' or 'facility'
    required int rateableId,
    required int overallRating,
    int? appointmentId,
    String? comment,
    bool isAnonymous = false,
    String? recommendation,
    // Doctor-specific ratings
    int? communicationRating,
    int? bedsideMannerRating,
    int? waitingTimeRating,
    int? knowledgeRating,
    // Facility-specific ratings
    int? cleanlinessRating,
    int? staffRating,
    int? facilitiesRating,
    int? accessibilityRating,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      final Map<String, dynamic> ratingData = {
        'rateable_type': rateableType,
        'rateable_id': rateableId,
        'overall_rating': overallRating,
        'is_anonymous': isAnonymous,
      };

      // Add optional fields
      if (appointmentId != null) ratingData['appointment_id'] = appointmentId;
      if (comment != null && comment.isNotEmpty) ratingData['comment'] = comment;
      if (recommendation != null) ratingData['recommendation'] = recommendation;

      // Add doctor-specific ratings
      if (rateableType == 'doctor') {
        if (communicationRating != null) ratingData['communication_rating'] = communicationRating;
        if (bedsideMannerRating != null) ratingData['bedside_manner_rating'] = bedsideMannerRating;
        if (waitingTimeRating != null) ratingData['waiting_time_rating'] = waitingTimeRating;
        if (knowledgeRating != null) ratingData['knowledge_rating'] = knowledgeRating;
      }

      // Add facility-specific ratings
      if (rateableType == 'facility') {
        if (cleanlinessRating != null) ratingData['cleanliness_rating'] = cleanlinessRating;
        if (staffRating != null) ratingData['staff_rating'] = staffRating;
        if (facilitiesRating != null) ratingData['facilities_rating'] = facilitiesRating;
        if (accessibilityRating != null) ratingData['accessibility_rating'] = accessibilityRating;
      }

      print('Submitting rating: $ratingData');

      final response = await _authService.authenticatedRequest(
        'POST',
        '/ratings',
        body: ratingData,
      );

      print('Rating submission response status: ${response.statusCode}');
      print('Rating submission response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      print('Rating submission error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get ratings for a specific doctor or facility
  Future<Map<String, dynamic>> getRatings({
    required String type, // 'doctor' or 'facility'
    required int id,
    int page = 1,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      final response = await _authService.authenticatedRequest(
        'GET',
        '/ratings/$type/$id?page=$page',
      );

      print('Get ratings response status: ${response.statusCode}');
      print('Get ratings response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load ratings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Get ratings error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get user's own ratings
  Future<Map<String, dynamic>> getUserRatings({int page = 1}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      final response = await _authService.authenticatedRequest(
        'GET',
        '/my-ratings?page=$page',
      );

      print('User ratings response status: ${response.statusCode}');
      print('User ratings response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user ratings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('User ratings error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get top-rated doctors
  Future<Map<String, dynamic>> getTopRatedDoctors({int limit = 10}) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      final response = await _authService.authenticatedRequest(
        'GET',
        '/top-rated-doctors?limit=$limit',
      );

      print('Top rated doctors response status: ${response.statusCode}');
      print('Top rated doctors response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load top rated doctors: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Top rated doctors error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get doctors with rating information (for browse doctors)
  Future<Map<String, dynamic>> getDoctorsWithRatings({
    int page = 1,
    int perPage = 10,
    String? specialty,
    String? location,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      String endpoint = '/doctors/approved?page=$page&per_page=$perPage';
      if (specialty != null && specialty.isNotEmpty) {
        endpoint += '&specialty=${Uri.encodeComponent(specialty)}';
      }
      if (location != null && location.isNotEmpty) {
        endpoint += '&location=${Uri.encodeComponent(location)}';
      }

      final response = await _authService.authenticatedRequest(
        'GET',
        endpoint,
      );

      print('Doctors with ratings response status: ${response.statusCode}');
      print('Doctors with ratings response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Doctors with ratings error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get facilities with rating information (for browse facilities)
  Future<Map<String, dynamic>> getFacilitiesWithRatings({
    int page = 1,
    int perPage = 10,
    String? type,
    String? location,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated. Please log in.');
      }

      String endpoint = '/public-facilities/approved?page=$page&per_page=$perPage';
      if (type != null && type.isNotEmpty) {
        endpoint += '&type=${Uri.encodeComponent(type)}';
      }
      if (location != null && location.isNotEmpty) {
        endpoint += '&location=${Uri.encodeComponent(location)}';
      }

      final response = await _authService.authenticatedRequest(
        'GET',
        endpoint,
      );

      print('Facilities with ratings response status: ${response.statusCode}');
      print('Facilities with ratings response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load facilities: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Facilities with ratings error: $e');
      throw Exception('Network error: $e');
    }
  }
}