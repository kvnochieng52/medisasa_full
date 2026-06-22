import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:xyvra_health/pages/find_doctor/doctor_chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailsPage({Key? key, required this.doctor}) : super(key: key);

  @override
  _DoctorDetailsPageState createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> {
  String? selectedSpecialty;
  DateTime selectedDay = DateTime.now(); // Track the selected day

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          widget.doctor['name'],
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
              // Doctor Introduction Card (Full Width)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(widget.doctor["image"]),
                        radius: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.doctor['name'],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.doctor['specialties'].join(", "),
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pin_drop,
                              color: Color(0xFF008faf)), // Pin icon
                          const SizedBox(width: 4),
                          Text(
                            "Location: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(widget.doctor['location']),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber), // Star icon
                          const SizedBox(width: 4),
                          Text(
                            "Rating: ${widget.doctor['rating']}/5",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      const SizedBox(height: 10),
                      // Actions Row
                      // Actions Row
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              _makePhoneCall('0713295853');
                            },
                            icon: const Icon(Icons.call,
                                color: Color(0xFF008faf)), // Call icon
                            label: const Text(
                              "Contact",
                              style: TextStyle(color: Color(0xFF008faf)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF008faf), // Button border color
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DoctorChatPage(doctor: widget.doctor),
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
                                color: Color(0xFF008faf), // Button border color
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              // handle favorite action here
                            },
                            icon: const Icon(Icons.favorite),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Doctor Clinic Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/hospital.png', // Use your hospital image here
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
                            const Text(
                              "Nairobi Hospital", // Change to widget.doctor['clinic'] if available
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.pin_drop,
                                    size: 20,
                                    color: Color(0xFF008faf)), // Pin icon
                                const SizedBox(width: 4),
                                Text(
                                  "Karen, Nairobi", // Change to dynamic data if available
                                  style: TextStyle(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Color(0xFF008faf),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "Monday-Sunday", // Change to dynamic data if available
                                  style: TextStyle(),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF008faf),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "8:00 AM - 6:00 PM", // Change to dynamic data if available
                                  style: TextStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Doctor Profile Card
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
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.doctor['profile'] ??
                            "Dr. ${widget.doctor['name']} is an experienced medical professional specializing in ${widget.doctor['specialties'].join(", ")}. They have been practicing for over 10 years and are committed to providing quality care.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Appointments Card (Moved Below Profile)
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
                            fontSize: 18, fontWeight: FontWeight.bold),
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
    String appointmentType = 'In-Person'; // Default appointment type

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
                // Radio buttons for appointment type
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.person), // User icon for In-Person
                          const SizedBox(width: 5),
                          const Text("In-Person"),
                        ],
                      ),
                      value: 'In-Person',
                      groupValue: appointmentType,
                      onChanged: (value) {
                        setState(() {
                          appointmentType = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero, // Remove padding
                    ),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons
                              .online_prediction), // Online icon for Online
                          const SizedBox(width: 5),
                          const Text("Online"),
                        ],
                      ),
                      value: 'Online',
                      groupValue: appointmentType,
                      onChanged: (value) {
                        setState(() {
                          appointmentType = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero, // Remove padding
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Reduced space
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: "Telephone"),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedTime,
                  items: <String>[
                    'Select Time',
                    '9:00 AM',
                    '10:00 AM',
                    '11:00 AM',
                    '1:00 PM',
                    '2:00 PM',
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
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Updated Button
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF008faf), // Background color
                borderRadius:
                    BorderRadius.circular(8), // Optional: rounded corners
              ),
              child: TextButton(
                child: const Text(
                  "Book Appointment",
                  style: TextStyle(color: Colors.white), // Text color
                ),
                onPressed: () {
                  // Handle the appointment booking logic here
                  Navigator.of(context).pop();

                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Successfully booked!"),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not launch dialer"),
        ),
      );
    }
  }
}
