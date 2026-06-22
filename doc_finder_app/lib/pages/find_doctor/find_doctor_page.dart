import 'package:xyvra_health/pages/find_doctor/modern_doctor_finder_simple.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';

class FindDoctorPage extends StatefulWidget {
  const FindDoctorPage({Key? key}) : super(key: key);

  @override
  _FindDoctorPageState createState() => _FindDoctorPageState();
}

class _FindDoctorPageState extends State<FindDoctorPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ModernDoctorFinderSimple(),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
