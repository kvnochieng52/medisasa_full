import 'package:xyvra_health/pages/dasboard/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/pages/find_doctor/find_doctor_page.dart';
import 'package:xyvra_health/pages/shop/medicine_shop_page.dart';
import 'package:xyvra_health/pages/favorites/favorite_doctors_page.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Ensure labels are always visible
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor:
          Color(0xFF008faf), // Use theme's primary color for selected items
      unselectedItemColor:
          Colors.grey.shade700, // Default (unselected) color as black
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (index) => _onItemTapped(
          context, index), // Call the method with context and index
      backgroundColor: Colors.transparent, // Remove background color
      elevation: 0, // Remove shadow under the navigation bar
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        // Navigate to the Dashboard page
        context.go('/dashboard');
        break;
      case 1: // Shop
        // Navigate to the new pharmacy shopping experience
        context.push('/pharmacy');
        break;
      case 2: // Search
        // Navigate to Find Doctor page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FindDoctorPage()),
        );
        break;
      case 3: // Favorites
        // Navigate to Favorites page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavoriteDoctorsPage()),
        );
        break;
    }
  }
}
