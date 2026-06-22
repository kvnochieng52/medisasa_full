import 'package:xyvra_health/pages/find_hospital/hospital_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xyvra_health/widgets/rating_display_widget.dart';
import 'package:xyvra_health/widgets/rating_form_widget.dart';

class HospitalDetailsPage extends StatefulWidget {
  final int? hospitalId;
  final Map<String, dynamic>? hospitalData;

  const HospitalDetailsPage({
    Key? key,
    this.hospitalId,
    this.hospitalData,
    // Legacy support
    @Deprecated('Use hospitalData instead') Map<String, dynamic>? hospital,
  }) : super(key: key);

  @override
  _HospitalDetailsPageState createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage> {
  DateTime selectedDay = DateTime.now(); // Track the selected day

  // Getter to handle hospitalId from data if not provided directly
  int? get _effectiveHospitalId => widget.hospitalId ?? widget.hospitalData?['id'];

  void _showRatingForm(BuildContext context) {
    if (_effectiveHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hospital ID not available for rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingFormWidget(
          rateableType: 'facility',
          rateableId: _effectiveHospitalId!,
          rateableName: widget.hospitalData?['name'] ?? 'Hospital',
          onRatingSubmitted: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you for your rating!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospital = widget.hospitalData ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          hospital['name'] ?? 'Hospital', // Update title to hospital name
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hospital Card (Full Width)
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    // Full-width hospital image with border radius
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10.0),
                      ),
                      child: Image.asset(
                        hospital["image"], // Use hospital photo
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital['name'] ?? 'Hospital', // Hospital name
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.pin_drop,
                                  color: Color(0xFF008faf)), // Pin icon
                              const SizedBox(width: 4),
                              Text(
                                hospital['location'] ?? 'Location not specified', // Hospital location
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber), // Star icon
                              const SizedBox(width: 4),
                              Text(
                                "Rating: ${hospital['rating'] ?? 'N/A'}/5", // Hospital rating
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Actions Row (Contact and Chat Buttons)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _makePhoneCall(
                                        '0713295853'); // Replace with hospital's contact number
                                  },
                                  icon: const Icon(Icons.call,
                                      color: Color(0xFF008faf)), // Call icon
                                  label: const Text(
                                    "Contact",
                                    style: TextStyle(color: Color(0xFF008faf)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(
                                          0xFF008faf), // Button border color
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HospitalChatPage(
                                          hospital: hospital), // Change to hospital chat page
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat,
                                    color: Color(0xFF008faf)), // Chat icon
                                label: const Text(
                                  "Chat",
                                  style: TextStyle(color: Color(0xFF008faf)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(
                                        0xFF008faf), // Button border color
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Hospital Profile and Specialties Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hospital['profile'] ??
                            "Lorem Ipsum is a placeholder text commonly used in the design and publishing industries. It's a scrambled version of a Latin text from de Finibus Bonorum et Malorum (The Extremes of Good and Evil) by Cicero, written in 45 BC. Here’s a standard passage of Lorem Ipsum",
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Services",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      // Hardcoded specialties
                      for (var specialty in [
                        "Cardiology",
                        "Neurology",
                        "Pediatrics",
                        "Orthopedics",
                        "General Surgery"
                      ]) // List specialties
                        Text("• $specialty"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Ratings Section
              if (_effectiveHospitalId != null) ...[
                RatingDisplayWidget(
                  rateableType: 'facility',
                  rateableId: _effectiveHospitalId!,
                  showAddRatingButton: true,
                  rateableName: hospital['name'],
                  onAddRating: () => _showRatingForm(context),
                ),
                const SizedBox(height: 8),
              ],

              // Appointments Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Book an Appointment",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: selectedDay,
                        availableGestures: AvailableGestures.all,
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Color(0xFF008faf), // Change today color
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFF008faf), // Change selected color
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false, // Remove 2 Weeks button
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            this.selectedDay =
                                selectedDay; // Update selected day
                          });
                          _showAppointmentDialog(
                              selectedDay); // Show dialog on day selection
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDialog(DateTime date) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedTime = 'Select Time'; // Placeholder for time selection
    String selectedService = 'General Clinic'; // Default appointment type

    // Format the date to DD-MM-YYYY
    String formattedDate =
        "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            // Use SingleChildScrollView to handle overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    "Book Appointment for",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18, // Adjust size as needed
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Label for service selection
                const Text(
                  "Select Service",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                // Dropdown for selecting service
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedService,
                  items: <String>[
                    'General Clinic',
                    'Dentist', // Added Dentist to the list
                    'Pediatrics',
                    'Dermatology',
                    'Orthopedics',
                    'Cardiology',
                    // Add more specialties as needed
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedService = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Text fields for input
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Time selection (could be implemented as a dropdown)
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedTime,
                  items: <String>[
                    'Select Time',
                    '10:00 AM',
                    '11:00 AM',
                    '12:00 PM',
                    '1:00 PM',
                    '2:00 PM',
                    '3:00 PM',
                    '4:00 PM',
                    '5:00 PM',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTime = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle appointment booking logic
                Navigator.of(context).pop();
              },
              child: const Text("Book Appointment"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }
}
