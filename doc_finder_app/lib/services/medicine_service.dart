import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine/medicine_model.dart';
import '../models/medicine/medicine_category_model.dart';
import '../models/medicine/cart_model.dart';
import '../models/api_config.dart';

class MedicineService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Get all medicines with filters
  static Future<MedicineResponse> getMedicines({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    int? subcategoryId,
    bool? requiresPrescription,
    bool? inStock,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (subcategoryId != null) {
        queryParams['subcategory_id'] = subcategoryId.toString();
      }
      if (requiresPrescription != null) {
        queryParams['requires_prescription'] = requiresPrescription.toString();
      }
      if (inStock != null) {
        queryParams['in_stock'] = inStock.toString();
      }

      final uri = Uri.parse('$baseUrl/medicines').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return MedicineResponse.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch medicines');
        }
      } else {
        throw Exception('Failed to fetch medicines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching medicines: $e');
    }
  }

  // Get single medicine by ID
  static Future<Medicine> getMedicine(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicines/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Medicine.fromJson(data['medicine']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch medicine');
        }
      } else {
        throw Exception('Failed to fetch medicine: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching medicine: $e');
    }
  }

  // Get medicine categories
  static Future<List<MedicineCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicine-categories'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['categories'] as List)
              .map((category) => MedicineCategory.fromJson(category))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get subcategories by category ID
  static Future<List<MedicineSubcategory>> getSubcategories(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicine-categories/$categoryId/subcategories'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return (data['subcategories'] as List)
              .map((subcategory) => MedicineSubcategory.fromJson(subcategory))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch subcategories');
        }
      } else {
        throw Exception('Failed to fetch subcategories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subcategories: $e');
    }
  }

  // Create medicine (authenticated)
  static Future<Medicine> createMedicine({
    required String name,
    String? description,
    required String medicineNumber,
    required double cost,
    required int categoryId,
    int? subcategoryId,
    String? manufacturer,
    String? strength,
    String? form,
    int quantityAvailable = 0,
    bool requiresPrescription = false,
    List<String>? conditions,
    File? image,
  }) async {
    try {
      // Get auth token
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      print('=== DEBUG: Creating medicine request ===');
      print('Name: $name');
      print('Medicine Number: $medicineNumber');
      print('Cost: $cost');
      print('Category ID: $categoryId');
      print('Subcategory ID: $subcategoryId');
      print('Quantity: $quantityAvailable');
      print('Requires Prescription: $requiresPrescription');
      print('Conditions: $conditions');
      print('Token exists: ${token.isNotEmpty}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/medicines'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add required fields
      request.fields['name'] = name.trim();
      request.fields['medicine_number'] = medicineNumber.trim();
      request.fields['cost'] = cost.toString();
      request.fields['category_id'] = categoryId.toString();
      request.fields['quantity_available'] = quantityAvailable.toString();
      request.fields['requires_prescription'] = requiresPrescription ? '1' : '0';

      // Add optional fields only if they have values
      if (description != null && description.trim().isNotEmpty) {
        request.fields['description'] = description.trim();
      }
      if (subcategoryId != null) {
        request.fields['subcategory_id'] = subcategoryId.toString();
      }
      if (manufacturer != null && manufacturer.trim().isNotEmpty) {
        request.fields['manufacturer'] = manufacturer.trim();
      }
      if (strength != null && strength.trim().isNotEmpty) {
        request.fields['strength'] = strength.trim();
      }
      if (form != null && form.trim().isNotEmpty) {
        request.fields['form'] = form.trim();
      }

      // Add conditions as array (only if conditions exist)
      if (conditions != null && conditions.isNotEmpty) {
        for (int i = 0; i < conditions.length; i++) {
          if (conditions[i].trim().isNotEmpty) {
            request.fields['conditions[$i]'] = conditions[i].trim();
          }
        }
      }

      // Add image if provided
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      print('=== DEBUG: Request fields ===');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('=== DEBUG: Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        if (data['success']) {
          return Medicine.fromJson(data['medicine']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create medicine');
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        final data = json.decode(responseBody);
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          String errorMessage = 'Validation errors:\n';
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '• $field: ${messages.join(', ')}\n';
            } else {
              errorMessage += '• $field: $messages\n';
            }
          });
          throw Exception(errorMessage);
        } else {
          throw Exception(data['message'] ?? 'Validation failed');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final data = json.decode(responseBody);
        throw Exception(data['message'] ?? 'Failed to create medicine: ${response.statusCode}');
      }
    } catch (e) {
      print('=== DEBUG: Exception caught ===');
      print('Exception type: ${e.runtimeType}');
      print('Exception message: $e');
      rethrow;
    }
  }

  // Update medicine (authenticated)
  static Future<Medicine> updateMedicine({
    required int id,
    required String name,
    String? description,
    required String medicineNumber,
    required double cost,
    required int categoryId,
    int? subcategoryId,
    String? manufacturer,
    String? strength,
    String? form,
    int quantityAvailable = 0,
    bool requiresPrescription = false,
    List<String>? conditions,
    File? image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST', // Laravel doesn't support PATCH/PUT with multipart
        Uri.parse('$baseUrl/medicines/$id'),
      );

      // Add method override for Laravel
      request.fields['_method'] = 'PUT';

      // Add headers
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Add fields
      request.fields['name'] = name;
      request.fields['medicine_number'] = medicineNumber;
      request.fields['cost'] = cost.toString();
      request.fields['category_id'] = categoryId.toString();
      request.fields['quantity_available'] = quantityAvailable.toString();
      request.fields['requires_prescription'] = requiresPrescription.toString();

      if (description != null) request.fields['description'] = description;
      if (subcategoryId != null) request.fields['subcategory_id'] = subcategoryId.toString();
      if (manufacturer != null) request.fields['manufacturer'] = manufacturer;
      if (strength != null) request.fields['strength'] = strength;
      if (form != null) request.fields['form'] = form;

      // Add conditions as array
      if (conditions != null) {
        for (int i = 0; i < conditions.length; i++) {
          request.fields['conditions[$i]'] = conditions[i];
        }
      }

      // Add image if provided
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success']) {
          return Medicine.fromJson(data['medicine']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update medicine');
        }
      } else {
        final data = json.decode(responseBody);
        throw Exception(data['message'] ?? 'Failed to update medicine: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating medicine: $e');
    }
  }

  // Delete medicine (authenticated)
  static Future<void> deleteMedicine(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/medicines/$id'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message'] ?? 'Failed to delete medicine');
        }
      } else {
        throw Exception('Failed to delete medicine: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting medicine: $e');
    }
  }

  // Upload medicine image (authenticated)
  static Future<String> uploadMedicineImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-medicine-image'),
      );

      // Add headers
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Add image file
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success']) {
          return data['image_url'];
        } else {
          throw Exception(data['message'] ?? 'Failed to upload image');
        }
      } else {
        final data = json.decode(responseBody);
        throw Exception(data['message'] ?? 'Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}