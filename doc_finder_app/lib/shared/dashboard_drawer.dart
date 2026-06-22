import 'package:xyvra_health/app_router.dart';
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/shared/subscription_gate.dart';
import 'package:xyvra_health/utils/safe_navigation.dart';
import 'package:xyvra_health/pages/facility/facilities/your_facilities/your_facilities.dart';
import 'package:xyvra_health/pages/facility/new_facility/new_facility.dart';
// import 'package:xyvra_health/pages/facility/your_facilities/your_facilities.dart'; // You'll need to create this page
import 'package:xyvra_health/pages/find_doctor/find_doctor_page.dart';
import 'package:xyvra_health/pages/find_hospital/find_hospital_page.dart';
import 'package:xyvra_health/pages/groups/new_group/new_group.dart';
import 'package:xyvra_health/pages/groups/your_groups/your_groups.dart';
import 'package:xyvra_health/pages/pharmacy/pharmacy_page.dart';
import 'package:xyvra_health/pages/profile/profile_page.dart';
import 'package:xyvra_health/pages/appointments/doctor_appointments_page.dart';
import 'package:xyvra_health/pages/prescriptions/prescriptions_history_page.dart';
import 'package:xyvra_health/pages/browse/browse_doctors_page.dart';
import 'package:xyvra_health/pages/browse/browse_facilities_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xyvra_health/models/api_config.dart';

class DashboardDrawer extends StatelessWidget {
  final Map<String, dynamic>? userProfile;

  const DashboardDrawer({
    Key? key,
    this.userProfile,
  }) : super(key: key);

  // Helper method to build the full image URL
  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    final String baseUrl = ApiConfig.webUrl;
    return '$baseUrl/storage/$imagePath';
  }

  // Helper methods for role-based access control
  bool _isAdmin() {
    final accountType = userProfile?['account_type'];
    return accountType == 3 || accountType == '3';
  }

  bool _isServiceProvider() {
    final accountType = userProfile?['account_type'];
    return accountType == 2 || accountType == '2';
  }

  bool _isApprovedServiceProvider() {
    final spApproved = userProfile?['sp_approved'];
    return _isServiceProvider() && (spApproved == 1 || spApproved == '1');
  }

  // Helper method to check if user can switch roles (approved as service provider)
  bool _canSwitchRoles() {
    final spApproved = userProfile?['sp_approved'];
    return spApproved == 1 || spApproved == '1';
  }

  // Helper method to check if user has access to administration features
  bool _hasAdministrationAccess() {
    return _isAdmin() || _isApprovedServiceProvider();
  }

  @override
  Widget build(BuildContext context) {
    // Extract user details with fallbacks
    final String userName = userProfile?['name'] ?? 'John Doe';
    final String userEmail = userProfile?['email'] ?? 'john.doe@example.com';
    final String? profileImage = userProfile?['profile_image'];

    // Debug: Get user role info
    final int? accountType = userProfile?['account_type'];
    final int? spApproved = userProfile?['sp_approved'];
    final String userRole = accountType == 3
        ? 'Admin'
        : accountType == 2
            ? (spApproved == 1
                ? 'Approved Service Provider'
                : 'Service Provider (Pending)')
            : 'Standard User';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF008faf),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(_buildImageUrl(profileImage)!) as ImageProvider
                  : const AssetImage(
                      'assets/images/passport.png'), // Fallback to default image
            ),
          ),
          // Show user role
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  Icons.badge,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Role: $userRole',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          // Account type toggle - only for users approved as service providers
          if (_canSwitchRoles())
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Switch Role:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isServiceProvider(),
                    onChanged: (bool value) {
                      _showRoleSwitchDialog(context, value);
                    },
                    activeThumbColor: Colors.green[600],
                    activeTrackColor: Colors.green[200],
                    inactiveThumbColor: Colors.blue[600],
                    inactiveTrackColor: Colors.blue[200],
                  ),
                ],
              ),
            ),
          // Top Level Quick Access
          ListTile(
            leading: const Icon(Icons.storefront, color: Colors.black),
            title: const Text('Shop', style: TextStyle(color: Colors.black)),
            onTap: () {
              context.push('/shop');
            },
          ),
          // Appointments - Only for approved Service Providers and Admins
          if (_isApprovedServiceProvider() || _isAdmin())
            ListTile(
              leading: const Icon(Icons.event_note, color: Colors.black),
              title: const Text('Appointments',
                  style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.of(context).pop();
                if (requiresSubscription(context,
                    featureName: 'Appointments')) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorAppointmentsPage(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.black),
            title: const Text('Prescriptions',
                style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrescriptionsHistoryPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology, color: Color(0xFF008faf)),
            title: const Text('Mental Health',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/mental-health');
            },
          ),

          const Divider(),

          ExpansionTile(
            leading: const Icon(Icons.search, color: Colors.black),
            title: const Text('Find', style: TextStyle(color: Colors.black)),
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.black),
                title:
                    const Text('Doctor', style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FindDoctorPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_city, color: Colors.black),
                title: const Text('Hospital',
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FindHospitalPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_pharmacy, color: Colors.black),
                title: const Text('Pharmacy',
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmacyPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const Divider(),

          ExpansionTile(
            leading: const Icon(Icons.list, color: Colors.black),
            title: const Text('Browse', style: TextStyle(color: Colors.black)),
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Browse Doctors',
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseDoctorsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.business, color: Colors.green),
                title: const Text('Browse Facilities',
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseFacilitiesPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Administration - Only for Admins and Approved Service Providers
          if (_hasAdministrationAccess())
            ExpansionTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.black),
              title: const Text('Administration',
                  style: TextStyle(color: Colors.black)),
              children: <Widget>[
                // Pharmacy Management
                ExpansionTile(
                  leading:
                      const Icon(Icons.local_pharmacy, color: Colors.black),
                  title: const Text('Pharmacy Management',
                      style: TextStyle(color: Colors.black)),
                  children: <Widget>[
                    ListTile(
                      leading:
                          const Icon(Icons.add_circle, color: Colors.black),
                      title: const Text('Add Medicine',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Pharmacy Management')) return;
                        context.push('/create-medicine');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory, color: Colors.black),
                      title: const Text('My Medicines',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Pharmacy Management')) return;
                        context.push('/my-medicines');
                      },
                    ),
                  ],
                ),

                // Products Management
                ExpansionTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.black),
                  title: const Text('Products Management',
                      style: TextStyle(color: Colors.black)),
                  children: <Widget>[
                    ListTile(
                      leading:
                          const Icon(Icons.add_business, color: Colors.black),
                      title: const Text('New Medical Product',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Products Management')) return;
                        context.push('/new-medical-product');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business_center,
                          color: Colors.black),
                      title: const Text('My Products',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Products Management')) return;
                        context.push('/my-products');
                      },
                    ),
                  ],
                ),

                // Blog Management - Only for Admins
                if (_isAdmin())
                  ExpansionTile(
                    leading: const Icon(Icons.article, color: Colors.black),
                    title: const Text('Blog Management',
                        style: TextStyle(color: Colors.black)),
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.add, color: Colors.black),
                        title: const Text('Create Blog',
                            style: TextStyle(color: Colors.black)),
                        onTap: () {
                          context.push('/create-blog');
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.list_alt, color: Colors.black),
                        title: const Text('My Blogs',
                            style: TextStyle(color: Colors.black)),
                        onTap: () {
                          context.push('/my-blogs');
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.trending_up, color: Colors.black),
                        title: const Text('Browse Blogs',
                            style: TextStyle(color: Colors.black)),
                        onTap: () {
                          context.push('/blogs');
                        },
                      ),
                    ],
                  ),

                // Facilities Management
                ExpansionTile(
                  leading: const Icon(Icons.business, color: Colors.black),
                  title: const Text('Facilities Management',
                      style: TextStyle(color: Colors.black)),
                  children: <Widget>[
                    ListTile(
                      leading:
                          const Icon(Icons.add_business, color: Colors.black),
                      title: const Text('New Facility',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Facilities Management')) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewFacilityPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business_center,
                          color: Colors.black),
                      title: const Text('Your Facilities',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Facilities Management')) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YourFacilitiesPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Support Groups Management
                ExpansionTile(
                  leading: const Icon(Icons.people, color: Colors.black),
                  title: const Text('Support Groups Management',
                      style: TextStyle(color: Colors.black)),
                  children: <Widget>[
                    ListTile(
                      leading:
                          const Icon(Icons.add_business, color: Colors.black),
                      title: const Text('New Group',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Support Groups')) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewGroupPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business_center,
                          color: Colors.black),
                      title: const Text('Your Groups',
                          style: TextStyle(color: Colors.black)),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (requiresSubscription(context,
                            featureName: 'Support Groups')) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YourGroupsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

          // Shopping Cart as a standalone item
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.black),
            title: const Text('Shopping Cart',
                style: TextStyle(color: Colors.black)),
            onTap: () {
              context.push('/cart');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title:
                const Text('Settings', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text('Logout', style: TextStyle(color: Colors.black)),
            onTap: () {
              _performLogout(context);
            },
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      print('Starting logout process...');

      // Close drawer first
      Navigator.of(context).pop();

      // For admin users, use the safest possible navigation to avoid Go Router errors
      final userProfile = AuthService().user;
      final accountType = userProfile?['account_type'];
      final isAdmin = accountType == 3 || accountType == '3';

      if (isAdmin) {
        print('Admin logout detected - using ultra-safe navigation');

        // Clear auth state quickly
        AuthService().logout().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print('Logout timeout for admin - proceeding with force logout');
          },
        );

        // Use force logout method for admins to bypass Go Router entirely
        SafeNavigation.forceLogout(context);
        return;
      }

      // For non-admin users, use standard safe navigation
      AuthService().logout().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Logout timeout - proceeding anyway');
        },
      );

      // Navigate immediately to login
      print('Navigating to login...');
      if (context.mounted) {
        SafeNavigation.navigateToLogin(context, replace: true);
      }
    } catch (e) {
      print('Logout error: $e');
      // Force navigation even on error
      if (context.mounted) {
        SafeNavigation.forceLogout(context);
      }
    }
  }

  void _showRoleSwitchDialog(
      BuildContext context, bool switchToServiceProvider) {
    final String targetRole =
        switchToServiceProvider ? 'Service Provider' : 'Standard User';
    final int targetAccountType = switchToServiceProvider ? 2 : 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Switch Role'),
          content: Text(
              'Are you sure you want to switch to $targetRole role? You will need to log in again.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Switch'),
              onPressed: () {
                Navigator.of(context).pop();
                _performRoleSwitch(context, targetAccountType, targetRole);
              },
            ),
          ],
        );
      },
    );
  }

  void _performRoleSwitch(
      BuildContext context, int accountType, String roleName) async {
    try {
      print('Starting role switch to: $roleName (type: $accountType)');

      // Store the navigator reference before any async operations
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Close drawer first
      navigator.pop();

      // Show loading indicator with timeout
      bool isLoading = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return PopScope(
            canPop: false,
            child: const AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Switching role...'),
                ],
              ),
            ),
          );
        },
      );

      // Add timeout to prevent hanging
      final result = await Future.any([
        AuthService().switchAccountType(accountType),
        Future.delayed(
            const Duration(seconds: 30),
            () => {
                  'success': false,
                  'message': 'Request timed out. Please try again.'
                }),
      ]);

      // Dismiss loading dialog only if it's still showing
      if (isLoading && context.mounted) {
        isLoading = false;
        navigator.pop();
      }

      if (result['success'] == true) {
        // Success - show brief message and navigate
        print('Role switch successful, navigating to login');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Role switched successfully! Please log in again.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Use a small delay to let the snackbar show, then navigate
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              AppRouter.safeNavigate(context, '/login', replace: true);
            }
          });
        }
      } else {
        // Show error message
        final errorMessage = result['message'] ?? 'Failed to switch role';
        print('Role switch failed: $errorMessage');

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Role switch error: $e');

      // Ensure loading dialog is dismissed
      try {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (popError) {
        print('Error dismissing dialog: $popError');
      }

      // Show error via snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to switch role. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

}
