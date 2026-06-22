import 'dart:convert';
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/pages/dasboard/widgets/latest_trend_widget.dart';
import 'package:xyvra_health/pages/dasboard/widgets/mental_health_section_widget.dart';
import 'package:xyvra_health/pages/dasboard/widgets/profile_status_widget.dart';
import 'package:xyvra_health/pages/dasboard/widgets/subscription_reminder_widget.dart';
import 'package:xyvra_health/shared/subscription_gate.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/pages/dasboard/widgets/find_section_widget.dart';
import 'package:xyvra_health/pages/dasboard/widgets/greetings_widget.dart';
import 'package:xyvra_health/pages/dasboard/widgets/in_store_section_widget.dart';
import 'package:xyvra_health/shared/app_bar.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';
import 'package:xyvra_health/shared/dashboard_drawer.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String userName = "John Doe";
  String? profileImage;
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/user-profile',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final sub = data['subscription'] as Map<String, dynamic>?;
          SubscriptionManager().update(
            accountType: (data['user'] as Map)['account_type'],
            subscription: sub,
          );
          if (!mounted) return;
          setState(() {
            userProfile = Map<String, dynamic>.from(data['user'] as Map);
            userProfile!['subscription'] = sub;
            userName = userProfile?['name'] ?? 'User';
            profileImage = userProfile?['profile_image'];
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    context.go('/profile'); // Use GoRouter instead of Navigator.pushNamed
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        userName: userName,
        profileImage: profileImage, // Pass profile image to CustomAppBar
      ),
      drawer: DashboardDrawer(
          userProfile: userProfile), // Pass userProfile to drawer
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Add the profile status widget at the top
              if (userProfile != null)
                ProfileStatusWidget(
                  userProfile: userProfile!,
                  onProfileTap: _navigateToProfile,
                ),
              const SizedBox(height: 16),
              GreetingsWidget(),
              const SizedBox(height: 20),
              // Add subscription reminder for unpaid service providers
              if (userProfile != null)
                SubscriptionReminderWidget(
                  userProfile: userProfile!,
                ),
              FindSectionWidget(),
              const SizedBox(height: 20),
              MentalHealthSectionWidget(),
              const SizedBox(height: 20),
              LatestTrendWidget(),
              const SizedBox(height: 20),
              InStoreSectionWidget(),
              const SizedBox(height: 100), // Bottom padding for better scrolling
            ],
          ),
        ),
      ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
