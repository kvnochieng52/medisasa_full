import 'package:xyvra_health/pages/find_doctor/find_doctor_page.dart';
import 'package:xyvra_health/pages/find_hospital/find_hospital_page.dart';
import 'package:xyvra_health/pages/lab/find_lab_page.dart';
import 'package:xyvra_health/pages/shop/medicine_shop_page.dart';
import 'package:xyvra_health/pages/support_group/find_support_group.dart';
import 'package:flutter/material.dart';

class FindSectionWidget extends StatelessWidget {
  FindSectionWidget({Key? key}) : super(key: key);

  // Function to build the icon and title with a tap gesture for navigation
  Widget buildIconWithTitle(
      String imagePath, String title, Widget page, BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToPage(context, page), // Handles navigation
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF008faf).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF008faf).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  imagePath,
                  height: 36,
                  width: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle page navigation
  void navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008faf).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color(0xFF008faf),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                buildIconWithTitle(
                  'assets/images/doctoricon.png',
                  'Doctor',
                  FindDoctorPage(),
                  context,
                ),
                buildIconWithTitle(
                  'assets/images/hospital.png',
                  'Hospital',
                  FindHospitalPage(),
                  context,
                ),
                buildIconWithTitle(
                  'assets/images/pharmacy.png',
                  'Pharmacy',
                  MedicineShopPage(),
                  context,
                ),
                buildIconWithTitle(
                  'assets/images/counselling.png',
                  'Support Group',
                  FindSupportGroupPage(),
                  context,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
