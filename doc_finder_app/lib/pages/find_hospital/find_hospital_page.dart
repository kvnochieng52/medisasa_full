import 'package:xyvra_health/pages/find_facility/modern_facility_finder.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';

class FindHospitalPage extends StatefulWidget {
  const FindHospitalPage({Key? key}) : super(key: key);

  @override
  _FindHospitalPageState createState() => _FindHospitalPageState();
}

class _FindHospitalPageState extends State<FindHospitalPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ModernFacilityFinder(),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
