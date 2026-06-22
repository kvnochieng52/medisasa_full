import 'package:xyvra_health/shared/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Appointment Reminder',
        'message': 'Your appointment with Dr. John is tomorrow at 10:00 AM.',
        'time': '09:00 AM',
        'date': 'Oct 12, 2024',
      },
      {
        'title': 'New Message',
        'message': 'You have a new message from Dr. Alice.',
        'time': '08:45 AM',
        'date': 'Oct 11, 2024',
      },
      {
        'title': 'Lab Results Ready',
        'message': 'Your lab results are ready. View them in your profile.',
        'time': '07:30 AM',
        'date': 'Oct 10, 2024',
      },
      {
        'title': 'Upcoming Event',
        'message': 'Join us for a health webinar on Oct 15, 2024.',
        'time': '05:00 PM',
        'date': 'Oct 09, 2024',
      },
      {
        'title': 'Update Profile',
        'message':
            'Please update your profile to keep your information current.',
        'time': '02:30 PM',
        'date': 'Oct 08, 2024',
      },
      {
        'title': 'Lab Results are Ready',
        'message':
            'Please update your profile to keep your information current.',
        'time': '02:30 PM',
        'date': 'Oct 08, 2024',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF008faf),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.all(10.0),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF008faf), // Placeholder color
                child: Icon(
                  Icons.notifications, // Placeholder icon
                  color: Colors.white,
                ),
              ),
              title: Text(
                notification['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['message']),
                  const SizedBox(height: 5),
                  Text(
                    '${notification['date']} • ${notification['time']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ), // F
    );
  }
}
