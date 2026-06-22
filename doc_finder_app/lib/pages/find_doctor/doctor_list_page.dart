import 'dart:math';
import 'package:xyvra_health/pages/find_doctor/doctor_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';
import 'doctor_details_page.dart'; // Import your details page

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({Key? key}) : super(key: key);

  @override
  _DoctorListPageState createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  int _selectedIndex = 0;
  final Random random = Random();

  // List of doctor images and names
  final List<Map<String, String>> doctorImages = [
    {
      "name": "Dr. Stanley Wahome",
      "image": 'assets/images/Dr.-Stanley-Wahome.png',
    },
    {
      "name": "Dr. Boniface Musila",
      "image": 'assets/images/Dr.-Boniface-Musila.png',
    },
    {
      "name": "Dr. Sharon Irungu",
      "image": 'assets/images/Dr.-Sharon-Irungu.png',
    },
    {
      "name": "Dr. Hussein Khalif",
      "image": 'assets/images/Dr.-Hussein-Khalif-Mohammed.jpg',
    },
  ];

  // List of specialties for random selection
  final List<List<String>> specialties = [
    ["Cardiology", "Pediatrics"],
    ["Dermatology", "Neurology"],
    ["Orthopedics", "Gastroenterology"],
  ];

  List<Map<String, dynamic>> doctors = []; // Initialize an empty list
  List<bool> favoriteStatus = []; // List to track favorite status

  @override
  void initState() {
    super.initState();
    generateDoctors(); // Generate doctors in initState
  }

  void generateDoctors() {
    doctors = List.generate(
      10,
      (index) {
        // Randomly select an image and name from the list
        final randomDoctor =
            index % doctorImages.length; // Cycle through the 3 doctors
        return {
          "name": doctorImages[randomDoctor]["name"],
          "specialties": specialties[random.nextInt(specialties.length)],
          "location": "${random.nextInt(10) + 1} km away", // Random distance
          "rating": (random.nextDouble() * 2 + 3)
              .toStringAsFixed(1), // Random rating between 3.0 and 5.0
          "image": doctorImages[randomDoctor]["image"], // Doctor image
        };
      },
    );

    // Initialize favorite status for each doctor as false
    favoriteStatus = List.generate(doctors.length, (index) => false);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctors',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf), // Set the app bar color
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: ListView.builder(
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to DoctorDetailsPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DoctorDetailsPage(doctor: doctor),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(doctor["image"]),
                            radius: 40, // Increased the image size
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor["name"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  doctor["specialties"].join(", "),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      doctor["location"],
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.yellow.shade600,
                                            size: 16),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${doctor["rating"]}/5',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DoctorDetailsPage(doctor: doctor),
                              ),
                            );
                          },
                          child: const Text(
                            "Details/Appointment",
                            style: TextStyle(color: Color(0xFF008faf)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF008faf), // Button border color
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DoctorChatPage(doctor: doctor),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat),
                          color: Color(0xFF008faf),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              // Toggle the favorite status
                              favoriteStatus[index] = !favoriteStatus[index];
                            });
                          },
                          icon: Icon(
                            favoriteStatus[index]
                                ? Icons.favorite // Filled heart if favorited
                                : Icons.favorite_border, // Outline if not
                            color: favoriteStatus[index]
                                ? Colors.red // Red if favorited
                                : Colors.grey, // Grey if not
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
