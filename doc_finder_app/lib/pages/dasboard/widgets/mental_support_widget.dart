import 'package:xyvra_health/pages/find_doctor/doctor_chat_page.dart';
import 'package:xyvra_health/pages/find_doctor/find_doctor_page.dart';
import 'package:xyvra_health/pages/support_group/find_support_group_page.dart';
import 'package:flutter/material.dart';

class MentalHealthSupportCard extends StatelessWidget {
  const MentalHealthSupportCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3, // Reduced shadow effect
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Minimize vertical space
          children: [
            const Text(
              "Mental Health Support. In need of help?",
              style: TextStyle(
                fontSize: 13, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            const Text(
              "If you or someone you know is struggling with mental health issues, we're here to help.",
              style: TextStyle(fontSize: 11), // Reduced font size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 80, // Reduced button width
                  height: 32, // Fixed height for compact button
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindDoctorPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF008faf),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4), // Reduced padding
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle:
                          const TextStyle(fontSize: 11), // Reduced text size
                    ),
                    child: const Text('Help'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FindSupportGroupPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4), // Reduced padding
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Support Groups',
                    style: TextStyle(
                      color: Color(0xFF008faf),
                      fontSize: 11, // Reduced text size
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
