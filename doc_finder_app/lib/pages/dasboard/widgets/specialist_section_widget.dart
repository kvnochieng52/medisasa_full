import 'package:xyvra_health/pages/find_doctor/doctor_list_page.dart';
import 'package:flutter/material.dart';

class SpecialistSectionWidget extends StatelessWidget {
  const SpecialistSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and department count
            Padding(
              padding: const EdgeInsets.all(
                  8.0), // Reduced padding for the title row
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Specialists',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(
                          width: 8.0), // Spacing between title and label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF008faf), // Background color
                          borderRadius:
                              BorderRadius.circular(100.0), // Rounded corners
                        ),
                        child: const Text(
                          '50', // Number of departments
                          style: TextStyle(
                            color: Colors.white, // Text color
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text('View All >',
                      style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            SizedBox(
              height: 220, // Height for three items
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0), // Reduced padding
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to DoctorListPage when the card is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DoctorListPage(), // Navigate to DoctorListPage
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color:
                                  const Color(0xFF008faf), // Left border color
                              width: 4.0, // Thickness of the left border
                            ),
                            top: BorderSide(
                              color: Colors.grey.shade300, // Top border color
                              width: 1.0, // Thickness of the top border
                            ),
                            right: BorderSide(
                              color: Colors.grey.shade300, // Right border color
                              width: 1.0, // Thickness of the right border
                            ),
                            bottom: BorderSide(
                              color:
                                  Colors.grey.shade300, // Bottom border color
                              width: 1.0, // Thickness of the bottom border
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 1.0,
                              horizontal: 1.0), // Adjusted padding
                          leading: Image.asset(
                            'assets/images/ml_department_one.png', // Placeholder image
                            height: 40, // Reduced height
                            width: 40, // Reduced width
                            fit: BoxFit.cover, // Ensure image fits nicely
                          ),
                          title: Text(
                            'Dental department long $index',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold), // Title of department
                          ),
                          subtitle: Text(
                            '100 doctors', // Number of doctors
                            style: const TextStyle(
                              fontSize: 11, // Reduced font size
                              color: Color(0xFF008faf),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (String value) {
                              // Handle the selected option
                              if (value == 'browse') {
                                // Navigate to browse doctors
                              } else if (value == 'book') {
                                // Navigate to book appointment
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'browse',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 16), // User icon
                                    const SizedBox(
                                        width:
                                            8), // Spacing between icon and text
                                    Text(
                                      'Browse Doctors',
                                      style: TextStyle(
                                        color: Colors.grey
                                            .shade600, // Reduced contrast text color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'book',
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16), // Calendar icon
                                    const SizedBox(
                                        width:
                                            8), // Spacing between icon and text
                                    Text(
                                      'Book Appointment',
                                      style: TextStyle(
                                        color: Colors.grey
                                            .shade600, // Reduced contrast text color
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert), // Icon for menu
                            color: Colors.grey
                                .shade50, // Light background color for the menu
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
