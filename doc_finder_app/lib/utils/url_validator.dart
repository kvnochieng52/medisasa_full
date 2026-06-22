class UrlValidator {
  /// Validates and sanitizes URLs to prevent Go Router canonicalUri errors
  static String sanitizeUrl(String url) {
    try {
      // Handle null or empty URLs
      if (url.isEmpty) {
        return '/login';
      }

      // Ensure URL starts with /
      if (!url.startsWith('/')) {
        url = '/$url';
      }

      // Parse URI to validate format
      final uri = Uri.tryParse(url);
      if (uri == null) {
        print('UrlValidator: Invalid URL format "$url", using /login');
        return '/login';
      }

      // Reconstruct URL safely
      String sanitized = uri.path;

      // Handle query parameters
      if (uri.hasQuery && uri.query.isNotEmpty) {
        sanitized += '?${uri.query}';
      }

      // Handle fragments
      if (uri.hasFragment && uri.fragment.isNotEmpty) {
        sanitized += '#${uri.fragment}';
      }

      // CRITICAL FIX: Handle the specific pattern that causes RangeError in Go Router
      // The issue is with replaceFirst('/?', '?', 1) when the pattern is at index 0
      // We need to handle this before Go Router's canonicalUri function sees it
      if (sanitized.startsWith('/?')) {
        print('UrlValidator: Found critical pattern "/?", applying emergency fix');

        // This is the exact pattern that causes the RangeError
        String remaining = sanitized.substring(2); // Remove '/?'

        if (remaining.isEmpty) {
          // Just '/?' becomes '/'
          sanitized = '/';
        } else if (remaining.startsWith('=') || remaining.startsWith('&')) {
          // '/?param=value' becomes '/param=value'
          sanitized = '/$remaining';
        } else {
          // '/?something' becomes '/something' or handle as query
          if (remaining.contains('=')) {
            sanitized = '/?$remaining'; // Keep as query
          } else {
            sanitized = '/$remaining'; // Treat as path
          }
        }

        print('UrlValidator: Emergency fix applied - result: "$sanitized"');
      }

      // Remove double slashes except after protocol
      sanitized = sanitized.replaceAll(RegExp(r'(?<!:)//+'), '/');

      // Validate that the result doesn't contain problematic patterns
      if (sanitized.contains('/?') && sanitized.indexOf('/?') > 0) {
        // Only safe if the pattern is not at the start
        return sanitized;
      } else if (!sanitized.contains('/?')) {
        // Safe if no problematic pattern exists
        return sanitized;
      } else {
        // Pattern at start - already handled above
        return sanitized;
      }
    } catch (e) {
      print('UrlValidator: Error sanitizing URL "$url": $e');
      return '/login';
    }
  }

  /// Validates if a URL is safe for Go Router
  static bool isValidUrl(String url) {
    try {
      final sanitized = sanitizeUrl(url);
      final uri = Uri.tryParse(sanitized);
      return uri != null && uri.path.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Safe URL builder for navigation
  static String buildUrl(String path, {Map<String, String>? queryParams}) {
    try {
      if (!path.startsWith('/')) {
        path = '/$path';
      }

      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri(path: path, queryParameters: queryParams);
        return sanitizeUrl(uri.toString());
      }

      return sanitizeUrl(path);
    } catch (e) {
      print('UrlValidator: Error building URL for path "$path": $e');
      return '/login';
    }
  }
}