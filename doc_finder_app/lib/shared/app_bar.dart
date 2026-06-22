import 'package:xyvra_health/pages/login/login_page.dart';
import 'package:xyvra_health/pages/profile/profile_page.dart';
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/app_router.dart';
import 'package:xyvra_health/utils/safe_navigation.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/models/api_config.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? profileImage; // Add profileImage parameter

  const CustomAppBar({
    Key? key,
    required this.userName,
    this.profileImage, // Make it optional
  }) : super(key: key);

  // Helper method to build the full image URL
  String? _buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    final String baseUrl = ApiConfig.webUrl;
    return '$baseUrl/storage/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF008faf), // Set the background color
      iconTheme: const IconThemeData(color: Colors.white), // Drawer icon color
      title: Center(
        child: Image.asset(
          'assets/images/logo_outline.png', // Replace with your logo image path
          height: 40, // Adjust logo height
        ),
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.notifications,
        //       color: Colors.white), // White notification icon
        //   onPressed: () {
        //     // Handle notification tap
        //   },
        // ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundImage: profileImage != null && profileImage!.isNotEmpty
                  ? NetworkImage(_buildImageUrl(profileImage)!) as ImageProvider
                  : const AssetImage(
                      'assets/images/passport.png'), // Fallback to default image
            ),
            onSelected: (value) {
              if (value == 'edit_profile') {
                // Navigate to ProfilePage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              } else if (value == 'logout') {
                _performLogout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  enabled: false, // Disable the user name option
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16, // Font size for user name
                          color: Colors.black, // Black color for user name
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(), // Separator line
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_profile',
                  child: Text('Edit Profile'),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }

  void _performLogout(BuildContext context) async {
    try {
      print('App Bar - Starting logout process...');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Clear auth state with timeout
      await AuthService().logout().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('App Bar - Logout timeout - proceeding anyway');
        },
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to login using SafeNavigation
      print('App Bar - Navigating to login...');
      if (context.mounted) {
        SafeNavigation.navigateToLogin(context, replace: true);
      }
    } catch (e) {
      print('App Bar - Logout error: $e');
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        // Force navigation using SafeNavigation
        SafeNavigation.forceLogout(context);
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
