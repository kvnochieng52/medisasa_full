import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SafeNavigation {
  /// Extremely safe navigation that bypasses Go Router if necessary
  static void navigateToLogin(BuildContext context, {bool replace = true}) {
    try {
      print('SafeNavigation: Attempting safe navigation to login');

      if (!context.mounted) {
        print('SafeNavigation: Context not mounted, skipping navigation');
        return;
      }

      // Try Go Router first with sanitized URL
      if (replace) {
        context.pushReplacement('/login');
      } else {
        context.push('/login');
      }

      print('SafeNavigation: Go Router navigation successful');
    } catch (e) {
      print('SafeNavigation: Go Router failed: $e');

      // Fallback to Navigator if Go Router fails
      try {
        if (context.mounted) {
          if (replace) {
            Navigator.of(context).pushReplacementNamed('/login');
          } else {
            Navigator.of(context).pushNamed('/login');
          }
          print('SafeNavigation: Navigator fallback successful');
        }
      } catch (fallbackError) {
        print('SafeNavigation: Navigator fallback also failed: $fallbackError');

        // Last resort: Use Navigator.pushAndRemoveUntil
        try {
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
            print('SafeNavigation: Navigator pushAndRemoveUntil successful');
          }
        } catch (lastResortError) {
          print('SafeNavigation: All navigation methods failed: $lastResortError');
          // At this point, we've exhausted all options
        }
      }
    }
  }

  /// Safe navigation for any route
  static void safeNavigate(BuildContext context, String route, {bool replace = true}) {
    try {
      print('SafeNavigation: Attempting safe navigation to: $route');

      if (!context.mounted) {
        print('SafeNavigation: Context not mounted, skipping navigation');
        return;
      }

      // Sanitize the route
      String sanitizedRoute = route;
      if (sanitizedRoute.startsWith('/?')) {
        // Handle the problematic pattern
        sanitizedRoute = sanitizedRoute.substring(2);
        if (!sanitizedRoute.startsWith('/')) {
          sanitizedRoute = '/$sanitizedRoute';
        }
      }

      if (!sanitizedRoute.startsWith('/')) {
        sanitizedRoute = '/$sanitizedRoute';
      }

      print('SafeNavigation: Using sanitized route: $sanitizedRoute');

      // Try Go Router first
      if (replace) {
        context.pushReplacement(sanitizedRoute);
      } else {
        context.push(sanitizedRoute);
      }

      print('SafeNavigation: Go Router navigation successful');
    } catch (e) {
      print('SafeNavigation: Go Router failed for route $route: $e');

      // Fallback to login if the specific route fails
      if (route != '/login') {
        navigateToLogin(context, replace: replace);
      } else {
        print('SafeNavigation: Even login navigation failed, this is critical');
      }
    }
  }

  /// Force immediate logout and navigation to login
  static void forceLogout(BuildContext context) {
    print('SafeNavigation: Force logout initiated');

    // Use microtask to ensure this happens after the current frame
    Future.microtask(() {
      try {
        if (context.mounted) {
          // Use the most direct Navigator method possible
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false, // Remove all routes
          );
          print('SafeNavigation: Force logout navigation successful');
        }
      } catch (e) {
        print('SafeNavigation: Force logout failed: $e');
      }
    });
  }
}