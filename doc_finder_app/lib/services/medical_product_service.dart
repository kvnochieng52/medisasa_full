import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xyvra_health/models/medical_product/medical_product_model.dart';
import 'package:xyvra_health/models/api_config.dart';

class MedicalProductService {
  static String _baseUrl = ApiConfig.baseUrl;

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders(
      {bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Get medical products with pagination and filtering
  static Future<MedicalProductResponse> getMedicalProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    String? category,
    bool? inStock,
    String? status,
    bool? lowStock,
    bool? expiringSoon,
    int? expiringDays,
    String sortBy = 'name',
    String sortOrder = 'asc',
    bool isPublic = true,
  }) async {
    try {
      final endpoint =
          isPublic ? '/public-medical-products' : '/medical-products';
      final uri = Uri.parse('$_baseUrl$endpoint');

      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (inStock != null) {
        queryParams['in_stock'] = inStock.toString();
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (lowStock != null) {
        queryParams['low_stock'] = lowStock.toString();
      }

      if (expiringSoon != null) {
        queryParams['expiring_soon'] = expiringSoon.toString();
        if (expiringDays != null) {
          queryParams['expiring_days'] = expiringDays.toString();
        }
      }

      final uriWithParams = uri.replace(queryParameters: queryParams);

      final headers = await _getHeaders(requireAuth: !isPublic);

      final response = await http.get(uriWithParams, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MedicalProductResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return MedicalProductResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to fetch medical products',
          error: errorData['error'],
        );
      }
    } catch (e) {
      return MedicalProductResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  // Get single medical product
  static Future<MedicalProduct?> getMedicalProduct(int id,
      {bool isPublic = true}) async {
    try {
      final endpoint =
          isPublic ? '/public-medical-products/$id' : '/medical-products/$id';
      final uri = Uri.parse('$_baseUrl$endpoint');

      final headers = await _getHeaders(requireAuth: !isPublic);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] && jsonData['data'] != null) {
          return MedicalProduct.fromJson(jsonData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching medical product: $e');
      return null;
    }
  }

  // Create new medical product (authenticated)
  static Future<MedicalProduct?> createMedicalProduct({
    required String name,
    String? description,
    required String batchNo,
    required String category,
    File? photo,
    required double cost,
    required int stockQuantity,
    String? manufacturer,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    bool needsPrescription = false,
    bool isAvailable = true,
    String? dosageForm,
    String? strength,
    List<String>? sideEffects,
    List<String>? conditions,
    List<String>? ingredients,
    String? storageConditions,
    String? usageInstructions,
    String? barcode,
    double? weight,
    String unitOfMeasure = 'pieces',
    int minimumStockLevel = 10,
    String? supplier,
    double? purchasePrice,
    String status = 'active',
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$_baseUrl/medical-products');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add form fields
      request.fields.addAll({
        'name': name,
        'batch_no': batchNo,
        'category': category,
        'cost': cost.toString(),
        'stock_quantity': stockQuantity.toString(),
        'needs_prescription': needsPrescription.toString(),
        'is_available': isAvailable.toString(),
        'unit_of_measure': unitOfMeasure,
        'minimum_stock_level': minimumStockLevel.toString(),
        'status': status,
      });

      if (description != null) request.fields['description'] = description;
      if (manufacturer != null) request.fields['manufacturer'] = manufacturer;
      if (manufacturingDate != null) {
        request.fields['manufacturing_date'] =
            manufacturingDate.toIso8601String().split('T')[0];
      }
      if (expiryDate != null) {
        request.fields['expiry_date'] =
            expiryDate.toIso8601String().split('T')[0];
      }
      if (dosageForm != null) request.fields['dosage_form'] = dosageForm;
      if (strength != null) request.fields['strength'] = strength;
      if (sideEffects != null) {
        request.fields['side_effects'] = json.encode(sideEffects);
      }
      if (conditions != null) {
        request.fields['conditions'] = json.encode(conditions);
      }
      if (ingredients != null) {
        request.fields['ingredients'] = json.encode(ingredients);
      }
      if (storageConditions != null)
        request.fields['storage_conditions'] = storageConditions;
      if (usageInstructions != null)
        request.fields['usage_instructions'] = usageInstructions;
      if (barcode != null) request.fields['barcode'] = barcode;
      if (weight != null) request.fields['weight'] = weight.toString();
      if (supplier != null) request.fields['supplier'] = supplier;
      if (purchasePrice != null)
        request.fields['purchase_price'] = purchasePrice.toString();

      // Add photo if provided
      if (photo != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', photo.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final jsonData = json.decode(responseBody);
        if (jsonData['success'] && jsonData['data'] != null) {
          return MedicalProduct.fromJson(jsonData['data']);
        }
      }

      return null;
    } catch (e) {
      print('Error creating medical product: $e');
      return null;
    }
  }

  // Update medical product (authenticated)
  static Future<MedicalProduct?> updateMedicalProduct({
    required int id,
    String? name,
    String? description,
    String? batchNo,
    String? category,
    File? photo,
    double? cost,
    int? stockQuantity,
    String? manufacturer,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    bool? needsPrescription,
    bool? isAvailable,
    String? dosageForm,
    String? strength,
    List<String>? sideEffects,
    List<String>? conditions,
    List<String>? ingredients,
    String? storageConditions,
    String? usageInstructions,
    String? barcode,
    double? weight,
    String? unitOfMeasure,
    int? minimumStockLevel,
    String? supplier,
    double? purchasePrice,
    String? status,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$_baseUrl/medical-products/$id');
      final request = http.MultipartRequest('POST', uri);

      // Add method override for PUT
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['_method'] = 'PUT';

      // Add form fields only if they are provided
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      if (batchNo != null) request.fields['batch_no'] = batchNo;
      if (category != null) request.fields['category'] = category;
      if (cost != null) request.fields['cost'] = cost.toString();
      if (stockQuantity != null)
        request.fields['stock_quantity'] = stockQuantity.toString();
      if (manufacturer != null) request.fields['manufacturer'] = manufacturer;
      if (manufacturingDate != null) {
        request.fields['manufacturing_date'] =
            manufacturingDate.toIso8601String().split('T')[0];
      }
      if (expiryDate != null) {
        request.fields['expiry_date'] =
            expiryDate.toIso8601String().split('T')[0];
      }
      if (needsPrescription != null)
        request.fields['needs_prescription'] = needsPrescription.toString();
      if (isAvailable != null)
        request.fields['is_available'] = isAvailable.toString();
      if (dosageForm != null) request.fields['dosage_form'] = dosageForm;
      if (strength != null) request.fields['strength'] = strength;
      if (sideEffects != null)
        request.fields['side_effects'] = json.encode(sideEffects);
      if (conditions != null)
        request.fields['conditions'] = json.encode(conditions);
      if (ingredients != null)
        request.fields['ingredients'] = json.encode(ingredients);
      if (storageConditions != null)
        request.fields['storage_conditions'] = storageConditions;
      if (usageInstructions != null)
        request.fields['usage_instructions'] = usageInstructions;
      if (barcode != null) request.fields['barcode'] = barcode;
      if (weight != null) request.fields['weight'] = weight.toString();
      if (unitOfMeasure != null)
        request.fields['unit_of_measure'] = unitOfMeasure;
      if (minimumStockLevel != null)
        request.fields['minimum_stock_level'] = minimumStockLevel.toString();
      if (supplier != null) request.fields['supplier'] = supplier;
      if (purchasePrice != null)
        request.fields['purchase_price'] = purchasePrice.toString();
      if (status != null) request.fields['status'] = status;

      // Add photo if provided
      if (photo != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', photo.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        if (jsonData['success'] && jsonData['data'] != null) {
          return MedicalProduct.fromJson(jsonData['data']);
        }
      }

      return null;
    } catch (e) {
      print('Error updating medical product: $e');
      return null;
    }
  }

  // Delete medical product (authenticated)
  static Future<bool> deleteMedicalProduct(int id) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$_baseUrl/medical-products/$id');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      }

      return false;
    } catch (e) {
      print('Error deleting medical product: $e');
      return false;
    }
  }

  // Update stock quantity (authenticated)
  static Future<MedicalProduct?> updateStock({
    required int id,
    required String action, // 'increase', 'decrease', 'set'
    required int quantity,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$_baseUrl/medical-products/$id/stock');
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': action,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] && jsonData['data'] != null) {
          return MedicalProduct.fromJson(jsonData['data']);
        }
      }

      return null;
    } catch (e) {
      print('Error updating stock: $e');
      return null;
    }
  }

  // Get categories
  static Future<List<String>> getCategories({bool isPublic = true}) async {
    try {
      final endpoint = isPublic
          ? '/public-medical-product-categories'
          : '/medical-product-categories';
      final uri = Uri.parse('$_baseUrl$endpoint');

      final headers = await _getHeaders(requireAuth: !isPublic);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] && jsonData['data'] != null) {
          return List<String>.from(jsonData['data']);
        }
      }

      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Search medical products by conditions
  static Future<MedicalProductResponse> searchByCondition(
    String condition, {
    int page = 1,
    int perPage = 15,
  }) async {
    return getMedicalProducts(
      page: page,
      perPage: perPage,
      search: condition,
      isPublic: true,
    );
  }

  // Get low stock products (for admin/management)
  static Future<MedicalProductResponse> getLowStockProducts({
    int page = 1,
    int perPage = 15,
  }) async {
    return getMedicalProducts(
      page: page,
      perPage: perPage,
      lowStock: true,
      isPublic: false,
    );
  }

  // Get expiring products (for admin/management)
  static Future<MedicalProductResponse> getExpiringProducts({
    int page = 1,
    int perPage = 15,
    int days = 30,
  }) async {
    return getMedicalProducts(
      page: page,
      perPage: perPage,
      expiringSoon: true,
      expiringDays: days,
      isPublic: false,
    );
  }

  // Get available products for shopping
  static Future<MedicalProductResponse> getAvailableProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    String? category,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    return getMedicalProducts(
      page: page,
      perPage: perPage,
      search: search,
      category: category,
      inStock: true,
      status: 'active',
      sortBy: sortBy,
      sortOrder: sortOrder,
      isPublic: true,
    );
  }
}
