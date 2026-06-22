import 'dart:math';
import 'package:xyvra_health/pages/find_doctor/doctor_chat_page.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_details_page.dart';
import 'package:xyvra_health/pages/find_hospital/hospital_chat_page.dart';
import 'package:xyvra_health/pages/find_hospital/hospital_details_page.dart';
import 'package:flutter/material.dart';
import 'package:xyvra_health/shared/bottom_navigation_bar.dart';

class HospitalListPage extends StatefulWidget {
  const HospitalListPage({Key? key}) : super(key: key);

  @override
  _HospitalListPageState createState() => _HospitalListPageState();
}

class _HospitalListPageState extends State<HospitalListPage> {
  int _selectedIndex = 0;
  final Random random = Random();

  // List of hospital images and names
  final List<Map<String, String>> hospitalImages = [
    {
      "name": "Nairobi Hospital",
      "image": 'assets/images/nairobi-hospital.jpg',
    },
    {
      "name": "Karen Hospital",
      "image": 'assets/images/karen-hospital.jpg',
    },
    {
      "name": "Avenue Hospital",
      "image": 'assets/images/Avenue-Hospital.jpg',
    },
    {
      "name": "The Matter Hospital",
      "image": 'assets/images/matter_hospital.jpg',
    },
  ];

  List<Map<String, dynamic>> hospitals = [];
  List<bool> favoriteStatus = [];

  @override
  void initState() {
    super.initState();
    generateHospitals();
  }

  void generateHospitals() {
    hospitals = List.generate(
      4,
      (index) {
        final hospital = hospitalImages[index];
        return {
          "name": hospital["name"],
          "location": "${random.nextInt(10) + 1} km away", // Random distance
          "rating": (random.nextDouble() * 2 + 3)
              .toStringAsFixed(1), // Random rating between 3.0 and 5.0
          "image": hospital["image"],
        };
      },
    );

    favoriteStatus = List.generate(hospitals.length, (index) => false);
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
          'Hospitals',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: ListView.builder(
        itemCount: hospitals.length,
        itemBuilder: (context, index) {
          final hospital = hospitals[index];
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HospitalDetailsPage(
                                  hospitalId: hospital['id'],
                                  hospitalData: hospital,
                                ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              hospital["image"],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital["name"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hospital["location"],
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Open Now",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.yellow.shade600,
                                            size: 16),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${hospital["rating"]}/5',
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
                                    HospitalDetailsPage(
                                  hospitalId: hospital['id'],
                                  hospitalData: hospital,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Details/Appointment",
                            style: TextStyle(color: Color(0xFF008faf)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF008faf),
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
                                    HospitalChatPage(hospital: hospital),
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
                              favoriteStatus[index] = !favoriteStatus[index];
                            });
                          },
                          icon: Icon(
                            favoriteStatus[index]
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: favoriteStatus[index]
                                ? Colors.red
                                : Colors.grey,
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
