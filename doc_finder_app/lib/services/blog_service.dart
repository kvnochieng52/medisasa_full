import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_config.dart';
import '../models/blog/blog_model.dart';
import '../models/blog/blog_response.dart';

class BlogService {
  static String _baseUrl = ApiConfig.baseUrl;

  // Get all blogs with pagination and filters
  static Future<BlogListResponse> getBlogs({
    int page = 1,
    int perPage = 10,
    bool? featured,
    bool? trending,
    String? search,
    String? tags,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/blogs');
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (featured != null) queryParams['featured'] = '1';
      if (trending != null) queryParams['trending'] = '1';
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags;

      final finalUri = uri.replace(queryParameters: queryParams);

      final response = await http.get(
        finalUri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return BlogListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching blogs: $e');
    }
  }

  // Get a specific blog by slug
  static Future<BlogDetailResponse> getBlogBySlug(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/blogs/$slug'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return BlogDetailResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load blog: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching blog: $e');
    }
  }

  // Get trending blogs
  static Future<List<Blog>> getTrendingBlogs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/blogs/trending'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((item) => Blog.fromJson(item))
              .toList();
        } else {
          throw Exception('API returned error');
        }
      } else {
        throw Exception(
            'Failed to load trending blogs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trending blogs: $e');
    }
  }

  // Get featured blogs
  static Future<List<Blog>> getFeaturedBlogs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/blogs/featured'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((item) => Blog.fromJson(item))
              .toList();
        } else {
          throw Exception('API returned error');
        }
      } else {
        throw Exception(
            'Failed to load featured blogs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured blogs: $e');
    }
  }

  // Get latest trends (combined trending, featured, and recent)
  static Future<LatestTrendsResponse> getLatestTrends() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/blogs/latest-trends'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return LatestTrendsResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load latest trends: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching latest trends: $e');
    }
  }

  // Get all available tags
  static Future<List<String>> getTags() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/blogs/tags'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<String>.from(data['data']);
        } else {
          throw Exception('API returned error');
        }
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tags: $e');
    }
  }

  // Get authentication token from storage
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print(
        'BlogService: Retrieved auth token: ${token != null ? 'exists' : 'null'}');
    return token;
  }

  // Get authenticated headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Create a new blog
  static Future<Blog> createBlog({
    required String title,
    required String excerpt,
    required String content,
    List<String>? tags,
    String status = 'draft',
    bool isFeatured = false,
    bool isTrending = false,
    File? featuredImage,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/blogs'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['title'] = title;
      request.fields['excerpt'] = excerpt;
      request.fields['content'] = content;
      request.fields['status'] = status;
      request.fields['is_featured'] = isFeatured.toString();
      request.fields['is_trending'] = isTrending.toString();

      if (tags != null && tags.isNotEmpty) {
        for (int i = 0; i < tags.length; i++) {
          request.fields['tags[$i]'] = tags[i];
        }
      }

      if (featuredImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'featured_image',
            featuredImage.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('BlogService: Create blog response status: ${response.statusCode}');
      print('BlogService: Create blog response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Blog.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create blog');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = errorData['message'] ?? 'Failed to create blog';

          // Add validation errors if they exist
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];
            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.map((msg) => '$field: $msg'));
              } else {
                errorMessages.add('$field: $messages');
              }
            });
            errorMessage += '\nValidation errors: ${errorMessages.join(', ')}';
          }

          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
              'Server error (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('BlogService: Exception in createBlog: $e');
      throw Exception('Error creating blog: $e');
    }
  }

  // Update an existing blog
  static Future<Blog> updateBlog({
    required int blogId,
    String? title,
    String? excerpt,
    String? content,
    List<String>? tags,
    String? status,
    bool? isFeatured,
    bool? isTrending,
    File? featuredImage,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final request = http.MultipartRequest(
        'POST', // Using POST with _method override as PUT doesn't support multipart
        Uri.parse('$_baseUrl/blogs/$blogId'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['_method'] = 'PUT';

      if (title != null) request.fields['title'] = title;
      if (excerpt != null) request.fields['excerpt'] = excerpt;
      if (content != null) request.fields['content'] = content;
      if (status != null) request.fields['status'] = status;
      if (isFeatured != null)
        request.fields['is_featured'] = isFeatured.toString();
      if (isTrending != null)
        request.fields['is_trending'] = isTrending.toString();

      if (tags != null) {
        for (int i = 0; i < tags.length; i++) {
          request.fields['tags[$i]'] = tags[i];
        }
      }

      if (featuredImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'featured_image',
            featuredImage.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Blog.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update blog');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            'Failed to update blog: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating blog: $e');
    }
  }

  // Delete a blog
  static Future<void> deleteBlog(int blogId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/blogs/$blogId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data['success']) {
          throw Exception(data['message'] ?? 'Failed to delete blog');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            'Failed to delete blog: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting blog: $e');
    }
  }

  // Get user's blogs
  static Future<BlogListResponse> getUserBlogs({
    int page = 1,
    int perPage = 10,
    String? status,
    String? search,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final uri = Uri.parse('$_baseUrl/my-blogs');
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final finalUri = uri.replace(queryParameters: queryParams);

      final response = await http.get(finalUri, headers: headers);

      if (response.statusCode == 200) {
        return BlogListResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load user blogs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user blogs: $e');
    }
  }

  // Upload featured image
  static Future<String> uploadFeaturedImage(File imageFile,
      {int? blogId}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload-blog-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      if (blogId != null) {
        request.fields['blog_id'] = blogId.toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data']['image_url'];
        } else {
          throw Exception(data['message'] ?? 'Failed to upload image');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            'Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
