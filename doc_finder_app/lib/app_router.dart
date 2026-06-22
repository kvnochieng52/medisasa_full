import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/pages/facility/edit_facility/edit_facility.dart';
import 'package:xyvra_health/pages/facility/facilities/your_facilities/your_facilities.dart';
import 'package:xyvra_health/pages/facility/new_facility/new_facility.dart';
import 'package:xyvra_health/pages/login/login_page.dart';
import 'package:xyvra_health/pages/profile/profile_page.dart';
import 'package:xyvra_health/pages/reset_password/new_password_page.dart';
import 'package:xyvra_health/utils/url_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/pages/dasboard/dashboard_page.dart';
import 'package:xyvra_health/pages/register/signup_page.dart';
import 'package:xyvra_health/pages/reset_password/reset_password.dart';
import 'package:xyvra_health/pages/register/email_confirmation.dart';
import 'package:xyvra_health/pages/blog/my_blogs_page.dart';
import 'package:xyvra_health/pages/blog/create_blog_page.dart';
import 'package:xyvra_health/pages/blog/blog_detail_page.dart';
import 'package:xyvra_health/pages/blog/trends_list_page.dart';
import 'package:xyvra_health/pages/mental_health/mental_health_page.dart';
import 'package:xyvra_health/pages/pharmacy/pharmacy_page.dart';
import 'package:xyvra_health/pages/pharmacy/checkout_page.dart';
import 'package:xyvra_health/pages/pharmacy/payment_page.dart';
import 'package:xyvra_health/pages/shop/medicine_shop_page.dart';
import 'package:xyvra_health/pages/shop/cart_page.dart';
import 'package:xyvra_health/pages/products/new_medical_product.dart';
import 'package:xyvra_health/pages/products/my_products_page.dart';
import 'package:xyvra_health/pages/products/edit_medical_product.dart';
import 'package:xyvra_health/pages/pharmacy/create_medicine_page.dart';
import 'package:xyvra_health/pages/pharmacy/my_medicines_page.dart';
import 'package:xyvra_health/pages/error/router_error_page.dart';
import 'package:xyvra_health/models/medicine/medicine_model.dart';
import 'package:xyvra_health/pages/subscription/subscription_payment_page.dart';
import 'package:xyvra_health/pages/subscription/payment_success_page.dart';
import 'package:xyvra_health/shared/subscription_gate.dart';

// Create a listenable that notifies when auth state changes
class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._internal();
  factory AuthNotifier() => _instance;
  AuthNotifier._internal();

  bool get isAuthenticated {
    final result = AuthService().isAuthenticated;
    print('AuthNotifier: isAuthenticated called - result: $result');
    return result;
  }

  void notify() {
    print('AuthNotifier: Notifying listeners of auth state change...');
    notifyListeners();
    print('AuthNotifier: Listeners notified');
  }
}

class AppRouter {
  static final _authNotifier = AuthNotifier();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authNotifier,
    errorBuilder: (context, state) {
      print('AppRouter: Error occurred - ${state.error}');
      return RouterErrorPage(
        error: state.error?.toString() ?? 'Unknown routing error',
        exception: state.error is Exception ? state.error as Exception : null,
      );
    },
    redirect: (context, state) {
      try {
        final isAuthenticated = AuthService().isAuthenticated;
        final rawLocation = state.matchedLocation;

        print('AppRouter: Redirect check - isAuthenticated=$isAuthenticated');
        print('AppRouter: rawLocation=$rawLocation');

        // Sanitize the location first to prevent canonicalUri errors
        final currentLocation = UrlValidator.sanitizeUrl(rawLocation);

        print('AppRouter: sanitizedLocation=$currentLocation');

        // Additional check for the specific problematic pattern
        if (rawLocation.startsWith('/?')) {
          print('AppRouter: Detected problematic pattern "/?", using ultra-safe fallback');
          return UrlValidator.sanitizeUrl('/login');
        }

        final publicRoutes = [
          '/login',
          '/signup',
          '/reset-password',
          '/email-confirmation',
          '/new-password',
        ];

        final isPublicRoute = publicRoutes.contains(currentLocation);

        print('AppRouter: isPublicRoute=$isPublicRoute for location=$currentLocation');

        // If authenticated and trying to access public routes, redirect to dashboard
        if (isAuthenticated && isPublicRoute) {
          print('AppRouter: Redirecting authenticated user from $currentLocation to /dashboard');
          return UrlValidator.sanitizeUrl('/dashboard');
        }

        // If not authenticated and trying to access protected route, redirect to login
        if (!isAuthenticated && !isPublicRoute) {
          print('AppRouter: Redirecting unauthenticated user from $currentLocation to /login');
          return UrlValidator.sanitizeUrl('/login');
        }

        print('AppRouter: No redirect needed for $currentLocation');
        return null;
      } catch (e) {
        print('AppRouter: Error in redirect logic: $e');
        // Safe fallback to login on any error
        return UrlValidator.sanitizeUrl('/login');
      }
    },
    routes: [
      // Your existing routes...
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          print('AppRouter: Building LoginPage');
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) {
          print('AppRouter: Building SignUpPage');
          return const SignUpPage();
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          print('AppRouter: Building ResetPasswordPage');
          return const ResetPasswordPage();
        },
      ),
      GoRoute(
        path: '/email-confirmation',
        name: 'email-confirmation',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          print('AppRouter: Building EmailConfirmation with email: $email');
          return EmailConfirmationPage(email: email);
        },
      ),
      GoRoute(
        path: '/subscription-payment',
        name: 'subscription-payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final currentPlan = extra?['currentPlan'] as String?;
          print('AppRouter: Building SubscriptionPaymentPage currentPlan=$currentPlan');
          return SubscriptionPaymentPage(currentPlanSlug: currentPlan);
        },
      ),

      // Payment success landing page
      GoRoute(
        path: '/payment-success',
        builder: (context, state) => const PaymentSuccessPage(),
      ),

      // Deep-link return routes — DPO Pay redirects via xyvrahealth:///payment/*
      // Triple-slash URIs give path=/payment/*, double-slash URIs give path=/*
      // Both variants handled so GoRouter never shows an error screen.
      GoRoute(
        path: '/payment/success',
        redirect: (context, state) => '/payment-success',
      ),
      GoRoute(
        path: '/payment/failed',
        redirect: (context, state) => '/subscription-payment',
      ),
      GoRoute(
        path: '/payment/cancel',
        redirect: (context, state) => '/subscription-payment',
      ),
      // Fallback for double-slash URIs: xyvrahealth://payment/success → host=payment, path=/success
      GoRoute(
        path: '/success',
        redirect: (context, state) => '/payment-success',
      ),
      GoRoute(
        path: '/failed',
        redirect: (context, state) => '/subscription-payment',
      ),
      GoRoute(
        path: '/cancel',
        redirect: (context, state) => '/subscription-payment',
      ),
      GoRoute(
        path: '/new-password',
        name: 'new-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          print(
              'AppRouter: Building NewPasswordPage with email: $email, code: $code');
          return NewPasswordPage(email: email, code: code);
        },
      ),
      // Protected routes...
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          print('AppRouter: Building DashboardPage');
          return const DashboardPage();
        },
      ),

      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          print('AppRouter: Building ProfilePage');
          return const ProfilePage();
        },
      ),

      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (context, state) {
          print('AppRouter: Building MedicineShopPage');
          return const MedicineShopPage();
        },
      ),

      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) {
          print('AppRouter: Building CartPage');
          return const CartPage();
        },
      ),

      GoRoute(
        path: '/new-facility',
        name: '/new-facility',
        builder: (context, state) => const SubscriptionGate(
          featureName: 'Facilities Management',
          child: NewFacilityPage(),
        ),
      ),

      GoRoute(
        path: '/your-facilities',
        name: '/your-facilities',
        builder: (context, state) => const SubscriptionGate(
          featureName: 'Facilities Management',
          child: YourFacilitiesPage(),
        ),
      ),

      GoRoute(
        path: '/edit-facility/:facilityId', // Use path parameter for facilityId
        name: 'edit-facility',
        builder: (context, state) {
          // Get the facilityId from path parameters
          final facilityId =
              int.tryParse(state.pathParameters['facilityId'] ?? '0') ?? 0;

          // Get the title from query parameters (optional)
          final title = state.uri.queryParameters['title'] ?? '';

          return EditFacilityPage(
            facilityId: facilityId,
            title: title.isNotEmpty ? title : null,
          );
        },
      ),

      // Medical Product management routes
      GoRoute(
        path: '/my-products',
        name: 'my-products',
        builder: (context, state) => const SubscriptionGate(
          featureName: 'Products Management',
          child: MyProductsPage(),
        ),
      ),

      GoRoute(
        path: '/new-medical-product',
        name: 'new-medical-product',
        builder: (context, state) => const SubscriptionGate(
          featureName: 'Products Management',
          child: NewMedicalProductPage(),
        ),
      ),

      GoRoute(
        path: '/edit-medical-product',
        name: 'edit-medical-product',
        builder: (context, state) {
          final product = state.extra as Map<String, dynamic>?;
          if (product == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid product data')),
            );
          }
          print('AppRouter: Building EditMedicalProductPage for product ${product['id']}');
          return EditMedicalProductPage(product: product);
        },
      ),

      // Medicine management routes
      GoRoute(
        path: '/create-medicine',
        name: 'create-medicine',
        builder: (context, state) => const SubscriptionGate(
          featureName: 'Pharmacy Management',
          child: CreateMedicinePage(),
        ),
      ),

      GoRoute(
        path: '/my-medicines',
        name: 'my-medicines',
        builder: (context, state) => const SubscriptionGate(
          featureName: 'Pharmacy Management',
          child: MyMedicinesPage(),
        ),
      ),

      GoRoute(
        path: '/edit-medicine',
        name: 'edit-medicine',
        builder: (context, state) {
          final medicineData = state.extra as Map<String, dynamic>?;
          Medicine? medicine;
          if (medicineData != null) {
            try {
              medicine = Medicine.fromJson(medicineData);
            } catch (e) {
              print('Error converting medicine data: $e');
            }
          }
          print('AppRouter: Building CreateMedicinePage for editing');
          return CreateMedicinePage(medicine: medicine);
        },
      ),

      // Blog management routes
      GoRoute(
        path: '/my-blogs',
        name: 'my-blogs',
        builder: (context, state) {
          print('AppRouter: Building MyBlogsPage');
          return const MyBlogsPage();
        },
      ),

      GoRoute(
        path: '/create-blog',
        name: 'create-blog',
        builder: (context, state) {
          print('AppRouter: Building CreateBlogPage');
          return const CreateBlogPage();
        },
      ),

      GoRoute(
        path: '/edit-blog/:blogId',
        name: 'edit-blog',
        builder: (context, state) {
          final blogId = int.tryParse(state.pathParameters['blogId'] ?? '');
          if (blogId == null || blogId <= 0) {
            return const Scaffold(
              body: Center(child: Text('Invalid blog ID')),
            );
          }
          print('AppRouter: Building EditBlogPage for blog $blogId');
          // We'll need to fetch the blog and pass it to CreateBlogPage
          // For now, just go to create page (will be enhanced)
          return const CreateBlogPage();
        },
      ),

      // Public blog routes
      GoRoute(
        path: '/blogs',
        name: 'blogs',
        builder: (context, state) {
          print('AppRouter: Building TrendsListPage');
          return const TrendsListPage();
        },
      ),

      GoRoute(
        path: '/blog/:slug',
        name: 'blog-detail',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          if (slug.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid blog slug')),
            );
          }
          print('AppRouter: Building BlogDetailPage for slug: $slug');
          return BlogDetailPage(slug: slug);
        },
      ),

      GoRoute(
        path: '/mental-health',
        name: 'mental-health',
        builder: (context, state) => const MentalHealthPage(),
      ),

      // Pharmacy shopping flow
      GoRoute(
        path: '/pharmacy',
        name: 'pharmacy',
        builder: (context, state) => const PharmacyPage(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckOutPage(),
      ),
      GoRoute(
        path: '/checkout/payment',
        name: 'checkout-payment',
        builder: (context, state) => const PharmacyPaymentPage(),
      ),
    ],
  );

  // Safe navigation to prevent race conditions and malformed URLs
  static void safeNavigate(BuildContext context, String route, {bool replace = false}) {
    try {
      // Sanitize the route to prevent Go Router errors
      final sanitizedRoute = UrlValidator.sanitizeUrl(route);

      print('AppRouter: Safe navigating from "$route" to "$sanitizedRoute" (replace: $replace)');

      if (!context.mounted) {
        print('AppRouter: Context not mounted, skipping navigation');
        return;
      }

      // Use a small delay to prevent race conditions
      Future.microtask(() {
        try {
          if (context.mounted) {
            if (replace) {
              context.pushReplacement(sanitizedRoute);
            } else {
              context.push(sanitizedRoute);
            }
          }
        } catch (e) {
          print('AppRouter: Navigation error for route "$sanitizedRoute": $e');
          // Fallback to login on any navigation error
          if (context.mounted && sanitizedRoute != '/login') {
            try {
              context.pushReplacement('/login');
            } catch (fallbackError) {
              print('AppRouter: Fallback navigation also failed: $fallbackError');
            }
          }
        }
      });
    } catch (e) {
      print('AppRouter: Safe navigate error: $e');
      // Last resort fallback
      if (context.mounted) {
        try {
          context.pushReplacement('/login');
        } catch (fallbackError) {
          print('AppRouter: Last resort navigation failed: $fallbackError');
        }
      }
    }
  }

  // SIMPLE METHOD 1: Using query parameters
  static void goToEmailConfirmation(BuildContext context, String email) {
    print('AppRouter: Navigating to email confirmation with email: $email');
    try {
      final safeUrl = UrlValidator.buildUrl('/email-confirmation', queryParams: {'email': email});
      context.go(safeUrl);
    } catch (e) {
      print('AppRouter: Error navigating to email confirmation: $e');
      safeNavigate(context, '/email-confirmation');
    }
  }

  // SIMPLE METHOD 2: Using extra data (even cleaner!)
  static void goToEmailConfirmationWithExtra(
      BuildContext context, String email) {
    print('AppRouter: Navigating to email confirmation with email: $email');
    try {
      context.go('/email-confirmation', extra: email);
    } catch (e) {
      print('AppRouter: Error navigating with extra: $e');
      safeNavigate(context, '/email-confirmation');
    }
  }

  // SIMPLE METHOD 3: Using named route with query parameters
  static void goToEmailConfirmationNamed(BuildContext context, String email) {
    print('AppRouter: Navigating to email confirmation with email: $email');
    try {
      context.goNamed(
        'email-confirmation',
        queryParameters: {'email': email},
      );
    } catch (e) {
      print('AppRouter: Error navigating named route: $e');
      safeNavigate(context, '/email-confirmation');
    }
  }

  // Notify the router about auth state changes
  static void notifyAuthChange() {
    print('AppRouter: Auth state change notification received');
    _authNotifier.notify();
  }

  // Get current auth state
  static bool get isAuthenticated => AuthService().isAuthenticated;

  // Force router refresh
  static void refresh() {
    print('AppRouter: Forcing router refresh...');
    _authNotifier.notify();
  }
}
