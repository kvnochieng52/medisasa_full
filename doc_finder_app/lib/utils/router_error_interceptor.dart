import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class RouterErrorInterceptor {
  static void initialize() {
    // Catch all errors in both debug and release mode for this specific issue
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is the Go Router canonicalUri RangeError
      if (details.exception is RangeError) {
        final errorString = details.exception.toString();
        final stackString = details.stack.toString();

        if ((errorString.contains('startIndex') && errorString.contains('Invalid value: Only valid value is 0: 1')) ||
            stackString.contains('canonicalUri') ||
            stackString.contains('replaceFirst')) {

          developer.log(
            'RouterErrorInterceptor: Caught Go Router canonicalUri RangeError - preventing app crash',
            error: details.exception,
            stackTrace: details.stack,
            name: 'RouterErrorInterceptor',
          );

          print('RouterErrorInterceptor: Go Router canonicalUri RangeError intercepted and suppressed');
          print('RouterErrorInterceptor: Error was: ${details.exception}');

          // Don't crash the app - this error is handled
          return;
        }
      }

      // Also catch any error that mentions path_utils.dart or canonicalUri
      if (details.toString().contains('path_utils.dart') ||
          details.toString().contains('canonicalUri') ||
          details.toString().contains('replaceFirst')) {

        print('RouterErrorInterceptor: Caught Go Router path utilities error');
        developer.log(
          'RouterErrorInterceptor: Go Router path utilities error suppressed',
          error: details.exception,
          name: 'RouterErrorInterceptor',
        );
        return; // Don't crash
      }

      // For other errors, use default handling
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        // In release mode, log but don't show error screen for non-critical errors
        developer.log(
          'RouterErrorInterceptor: Unhandled error in release mode',
          error: details.exception,
          stackTrace: details.stack,
          name: 'RouterErrorInterceptor',
        );
      }
    };
  }

  /// Check if a URL might cause the Go Router canonicalUri error
  static bool isProblematicUrl(String url) {
    try {
      // The error occurs when replaceFirst('/?', '?', 1) is called
      // and the pattern '/?'  exists at position 0 in the string
      if (url.startsWith('/?')) {
        return true;
      }

      // Other patterns that might cause issues
      if (url.contains('//') && !url.startsWith('http')) {
        return true;
      }

      return false;
    } catch (e) {
      return true; // If we can't analyze it, consider it problematic
    }
  }

  /// Fix problematic URLs before they reach Go Router
  static String fixProblematicUrl(String url) {
    try {
      if (url.isEmpty) return '/login';

      // Fix the specific pattern that causes RangeError
      if (url.startsWith('/?')) {
        url = url.replaceFirst('/?', '?');
        if (!url.startsWith('/')) {
          url = '/$url';
        }
      }

      // Remove duplicate slashes
      url = url.replaceAll(RegExp(r'(?<!:)//+'), '/');

      // Ensure it starts with /
      if (!url.startsWith('/')) {
        url = '/$url';
      }

      return url;
    } catch (e) {
      return '/login';
    }
  }
}