import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FileUploadService {
  static const String baseUrl =
      'YOUR_SERVER_BASE_URL'; // Replace with your server URL

  /// Upload a single file
  static Future<Map<String, dynamic>> uploadSingleFile(
      File file, String endpoint,
      {Map<String, String>? additionalFields}) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));

      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(responseData),
        };
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload multiple files
  static Future<Map<String, dynamic>> uploadMultipleFiles(
      List<File> files, String endpoint,
      {Map<String, String>? additionalFields}) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));

      // Add all files
      for (int i = 0; i < files.length; i++) {
        request.files
            .add(await http.MultipartFile.fromPath('files_$i', files[i].path));
      }

      // Add file count
      request.fields['file_count'] = files.length.toString();

      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(responseData),
        };
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Save user profile data
  static Future<Map<String, dynamic>> saveProfileData(
      Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save-profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to save profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Complete registration
  static Future<Map<String, dynamic>> completeRegistration(
      Map<String, dynamic> registrationData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complete-registration'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Registration failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

/// File validation utilities
class FileValidator {
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentExtensions = ['pdf'];
  static const List<String> allowedExtensions = [
    ...allowedImageExtensions,
    ...allowedDocumentExtensions
  ];
  static const int maxFileSizeMB = 10;

  static bool isValidFile(File file) {
    String extension = file.path.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  static bool isValidFileSize(File file) {
    int fileSizeInBytes = file.lengthSync();
    int fileSizeInMB = fileSizeInBytes ~/ (1024 * 1024);
    return fileSizeInMB <= maxFileSizeMB;
  }

  static String? validateFile(File file) {
    if (!isValidFile(file)) {
      return 'Invalid file format. Allowed formats: ${allowedExtensions.join(', ')}';
    }

    if (!isValidFileSize(file)) {
      return 'File size too large. Maximum size: ${maxFileSizeMB}MB';
    }

    return null; // File is valid
  }

  static List<String> validateFiles(List<File> files) {
    List<String> errors = [];

    for (int i = 0; i < files.length; i++) {
      String? error = validateFile(files[i]);
      if (error != null) {
        errors.add('File ${i + 1}: $error');
      }
    }

    return errors;
  }
}
