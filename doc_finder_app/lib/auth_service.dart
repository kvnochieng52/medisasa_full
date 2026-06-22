import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/app_router.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  // Enhanced isAuthenticated with debug logging
  bool get isAuthenticated {
    final result = _token != null && _token!.isNotEmpty;
    print(
        'AuthService: isAuthenticated called - token=$_token, result=$result');
    return result;
  }

  // Initialize - check for stored token
  Future<void> init() async {
    print('AuthService: Initializing...');
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
    print(
        'AuthService: Initialized - isAuthenticated=$isAuthenticated, token=$_token');
  }

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('AuthService: Starting login for email: $email');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + '/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('AuthService: Login response status: ${response.statusCode}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final payload = responseData['data'] is Map<String, dynamic>
            ? responseData['data'] as Map<String, dynamic>
            : responseData;

        final newToken = payload['token'] ?? payload['access_token'];
        final newUser = payload['user'] ?? payload['user_data'] ?? responseData['user'];

        if (newToken == null || newToken.toString().isEmpty) {
          print('AuthService: Login failed - token missing in response');
          return {
            'success': false,
            'message': responseData['message'] ??
                'Login failed: authentication token not returned.',
          };
        }

        print(
            'AuthService: Login successful - token: $newToken, user: $newUser');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', newToken.toString());
        _token = newToken.toString();
        print('AuthService: Token stored and set: $_token');

        if (newUser != null) {
          await prefs.setString('user_data', jsonEncode(newUser));
          _user = newUser;
          print('AuthService: User data stored: $_user');
        }

        print(
            'AuthService: Post-login auth state - isAuthenticated: $isAuthenticated');
        return {'success': true, 'message': 'Login successful!'};
      } else if (response.statusCode == 401) {
        print('AuthService: Login failed - Invalid credentials');
        return {'success': false, 'message': 'Invalid email or password'};
      } else if (response.statusCode == 422) {
        print('AuthService: Login failed - Validation error');
        String errorMessage = 'Validation error';
        if (responseData.containsKey('errors')) {
          errorMessage = responseData['errors'].values.first[0];
        }
        return {'success': false, 'message': errorMessage};
      } else {
        print('AuthService: Login failed - Status: ${response.statusCode}');
        String errorMessage = responseData['message'] ?? 'Login failed';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('AuthService: Login error - Exception: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.'
      };
    }
  }

  // Logout method
  Future<void> logout() async {
    print('AuthService: Starting logout...');

    try {
      if (_token != null) {
        print('AuthService: Sending logout request to server...');
        await http.post(
          Uri.parse(ApiConfig.baseUrl + '/logout'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      print('AuthService: Logout API error: $e');
    } finally {
      _token = null;
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');

      print('AuthService: Logout completed - Auth state cleared');
      // Notify router of auth state change
      AppRouter.notifyAuthChange();
    }
  }

  // Make authenticated requests
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    final headers = {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final uri = Uri.parse(ApiConfig.baseUrl + endpoint);

    print('AuthService: Making authenticated $method request to $endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      case 'PATCH':
        return await http.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // NEW: Authenticated file upload method
  Future<Map<String, dynamic>> authenticatedFileUpload(
    String endpoint,
    List<File> files, {
    Map<String, String>? additionalFields,
    String fileFieldName = 'files',
  }) async {
    if (!isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.baseUrl + endpoint),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';

      // Add files
      for (int i = 0; i < files.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            '${fileFieldName}_$i',
            files[i].path,
          ),
        );
      }

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Add file count
      request.fields['file_count'] = files.length.toString();

      print('AuthService: Uploading ${files.length} files to $endpoint');

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(responseData),
        };
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // NEW: Single file upload method
  Future<Map<String, dynamic>> authenticatedSingleFileUpload(
    String endpoint,
    File file, {
    Map<String, String>? additionalFields,
    String fileFieldName = 'file',
  }) async {
    if (!isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.baseUrl + endpoint),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, file.path),
      );

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      print('AuthService: Uploading single file to $endpoint');

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(responseData),
        };
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // NEW: Authenticated multipart request for files and form data
  Future<http.Response> authenticatedMultipartRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? fields,
    Map<String, File>? files,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User is not authenticated');
    }

    try {
      var request = http.MultipartRequest(
        method.toUpperCase(),
        Uri.parse(ApiConfig.baseUrl + endpoint),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Accept'] = 'application/json';

      // Add fields
      if (fields != null) {
        for (var entry in fields.entries) {
          request.fields[entry.key] = entry.value.toString();
        }
      }

      // Add files
      if (files != null) {
        for (var entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value.path),
          );
        }
      }

      print('AuthService: Making authenticated multipart $method request to $endpoint');

      var streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      print('AuthService: Multipart request error: $e');
      rethrow;
    }
  }

  // Switch account type method
  Future<Map<String, dynamic>> switchAccountType(int accountType) async {
    print('AuthService: Switching account type to: $accountType');

    try {
      // Add timeout to the request
      final response = await authenticatedRequest(
        'POST',
        '/switch-account-type',
        body: {'account_type': accountType},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('AuthService: Switch account type response status: ${response.statusCode}');
      print('AuthService: Switch account type response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('AuthService: Account type switched successfully, clearing auth state');

        // Clear auth state synchronously to avoid hanging
        try {
          _token = null;
          _user = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          await prefs.remove('user_data');
          print('AuthService: Auth state cleared successfully');

          // Notify router of auth state change to trigger redirects
          print('AuthService: Notifying router of auth state change');
          AppRouter.notifyAuthChange();
        } catch (clearError) {
          print('AuthService: Error clearing auth state: $clearError');
        }

        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        print('AuthService: Switch account type failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to switch account type',
        };
      }
    } catch (e) {
      print('AuthService: Switch account type error: $e');
      return {
        'success': false,
        'message': e.toString().contains('timed out')
          ? 'Request timed out. Please check your connection.'
          : 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Force refresh auth state from storage
  Future<void> refreshAuthState() async {
    print('AuthService: Refreshing auth state from storage...');
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
    print(
        'AuthService: Auth state refreshed - isAuthenticated: $isAuthenticated');
  }
}
