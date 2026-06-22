import 'package:flutter/material.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';
import 'package:xyvra_health/pages/support_group/modern_support_group_finder.dart';

class FindSupportGroupPage extends StatefulWidget {
  const FindSupportGroupPage({Key? key}) : super(key: key);

  @override
  _FindSupportGroupPageState createState() => _FindSupportGroupPageState();
}

class _FindSupportGroupPageState extends State<FindSupportGroupPage> {
  int _selectedIndex = 2; // Support Group tab

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ModernSupportGroupFinder(),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}