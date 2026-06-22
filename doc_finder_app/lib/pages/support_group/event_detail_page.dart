import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String location;
  final String description; // New property for event description

  const EventDetailPage({
    Key? key,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description, // Require the description in the constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String telephone = '';
    String notes = '';

    return Scaffold(
      backgroundColor:
          Colors.grey[300], // Set the scaffold background color to grey
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the back button color to white
        ),
        backgroundColor: const Color(0xFF008faf),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Card(
            // Wrap the content in a Card
            color: Colors.white, // Set card background color to white
            elevation: 4, // Add elevation for a shadow effect
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // New section for icons
                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Color(0xFF008faf)),
                      const SizedBox(width: 8),
                      Text(date),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF008faf)),
                      const SizedBox(width: 8),
                      Text(time),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, color: Color(0xFF008faf)),
                      const SizedBox(width: 8),
                      Text(location),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // New section for event description
                  const Text(
                    "Description:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(description), // Display the description
                  const SizedBox(height: 20),
                  const Text(
                    "Register to Attend",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Name'),
                          onChanged: (value) => name = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Email'),
                          onChanged: (value) => email = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Telephone'),
                          onChanged: (value) => telephone = value,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your telephone';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Notes'),
                          onChanged: (value) => notes = value,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity, // Make the button full-width
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // Handle registration logic here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Registered successfully!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(
                                  0xFF008faf), // Set button background color
                            ),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
