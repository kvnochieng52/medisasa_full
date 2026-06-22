import 'package:xyvra_health/pages/find_hospital/hospital_chat_page.dart';
import 'package:xyvra_health/pages/support_group/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportGroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic> hospital;

  const SupportGroupDetailsPage({Key? key, required this.hospital})
      : super(key: key);

  @override
  _SupportGroupDetailsPageState createState() =>
      _SupportGroupDetailsPageState();
}

class _SupportGroupDetailsPageState extends State<SupportGroupDetailsPage> {
  List<Map<String, String>> events = [
    {
      "date": "10-10-2024",
      "time": "10:00 AM",
      "title": "Community Health Awareness",
      "location": "Community Center",
    },
    {
      "date": "15-10-2024",
      "time": "02:00 PM",
      "title": "Free Diabetes Checkup",
      "location": "Main Hospital",
    },
    {
      "date": "20-10-2024",
      "time": "11:00 AM",
      "title": "Mental Health Support Group",
      "location": "City Library",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          widget.hospital['name'],
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
                color: Colors.white,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10.0),
                      ),
                      child: Image.asset(
                        widget.hospital["image"],
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
                            widget.hospital['name'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.pin_drop,
                                  color: Color(0xFF008faf)),
                              const SizedBox(width: 4),
                              Text(
                                widget.hospital['location'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                "Rating: ${widget.hospital['rating']}/5",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _makePhoneCall('0713295853');
                                  },
                                  icon: const Icon(Icons.call,
                                      color: Color(0xFF008faf)),
                                  label: const Text(
                                    "Contact",
                                    style: TextStyle(color: Color(0xFF008faf)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF008faf),
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
                                          hospital: widget.hospital),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat,
                                    color: Color(0xFF008faf)),
                                label: const Text(
                                  "Chat",
                                  style: TextStyle(color: Color(0xFF008faf)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF008faf),
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

              // Profile Card (Added Above Video Card)

              // Events List Card
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upcoming Events",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              title: Row(
                                children: [
                                  const Icon(Icons.calendar_month,
                                      color: Color(0xFF008faf)),
                                  const SizedBox(width: 8),
                                  Text(
                                    event["title"]!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Date & Time: ${event["date"]} at ${event["time"]}"),
                                  Text("Location: ${event["location"]}"),
                                ],
                              ),
                              onTap: () {
                                // Navigate to EventDetailPage with event details
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailPage(
                                      title: event["title"]!,
                                      date: event["date"]!,
                                      time: event["time"]!,
                                      location: event["location"]!,
                                      description:
                                          'Join us for a day of health screenings, education, and fun activities for the whole family.',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 2,
                color: Colors.white,
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
                        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it ",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Video Carousel Card
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Informative Video",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 200, // Set height for video container
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // YouTube video link wrapped in a webview or an iframe
                            PageView(
                              children: [
                                // Placeholder for video
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Container(
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            // Play button
                            GestureDetector(
                              onTap: () {
                                _launchURL(
                                    'https://www.youtube.com/watch?v=0aL459zuA9Y');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(
                                    8.0), // Adjust size as needed
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF008faf),
                                  size: 40, // Adjust size as needed
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Photo Gallery Card
              Card(
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Photo Gallery",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 100, // Set height for photo gallery
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.asset(
                                  'assets/images/event1.jpg',
                                  width: 150,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.asset(
                                  'assets/images/event2.jpg',
                                  width: 150,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }
}
