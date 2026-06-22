import 'package:xyvra_health/shared/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'basic_details_tab.dart';
import 'sp_details_tab.dart';
import 'login_details_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _userType;
  TabController? _tabController;

  // Profile data storage
  Map<String, dynamic> profileData = {};

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    int tabCount = _userType == 'serviceProvider' ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onUserTypeChanged(String? userType) {
    setState(() {
      _userType = userType;
      profileData['userType'] = userType;
      _tabController?.dispose();
      _initializeTabController();
    });
  }

  void _updateProfileData(Map<String, dynamic> data) {
    setState(() {
      profileData.addAll(data);
    });
  }

  void _navigateToNextTab() {
    if (_tabController != null &&
        _tabController!.index < _tabController!.length - 1) {
      _tabController!.animateTo(_tabController!.index + 1);
    }
  }

  void _navigateToDashboard() {
    if (_userType == 'user') {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/serviceProviderDashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    int tabCount = _userType == 'serviceProvider' ? 3 : 2;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF008faf),
          bottom: _userType != null
              ? TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  indicatorColor: Colors.white,
                  tabs: [
                    const Tab(text: 'Basic Details'),
                    if (_userType == 'serviceProvider')
                      const Tab(text: 'S.P Details'),
                    const Tab(text: 'Confirmation'),
                  ],
                )
              : null,
        ),
        body: _userType != null
            ? TabBarView(
                controller: _tabController,
                children: [
                  // Basic Details Tab
                  BasicDetailsTab(
                    userType: _userType,
                    onUserTypeChanged: _onUserTypeChanged,
                    profileData: profileData,
                    onDataChanged: _updateProfileData,
                    onSave: () {
                      if (_userType == 'serviceProvider') {
                        _navigateToNextTab();
                      } else {
                        _navigateToNextTab();
                      }
                    },
                  ),

                  // Service Provider Details Tab (only visible for service providers)
                  if (_userType == 'serviceProvider')
                    ServiceProviderDetailsTab(
                      userType: _userType,
                      profileData: profileData,
                      onDataChanged: _updateProfileData,
                      onSave: _navigateToNextTab,
                    ),

                  // Login Details Tab
                  LoginDetailsTab(
                    profileData: profileData,
                    onDataChanged: _updateProfileData,
                    onSave: _navigateToDashboard,
                  ),
                ],
              )
            : BasicDetailsTab(
                userType: _userType,
                onUserTypeChanged: _onUserTypeChanged,
                profileData: profileData,
                onDataChanged: _updateProfileData,
                onSave: () {
                  if (_userType == 'serviceProvider') {
                    _navigateToNextTab();
                  } else {
                    _navigateToNextTab();
                  }
                },
              ),
        bottomNavigationBar: CustomBottomNavigationBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
