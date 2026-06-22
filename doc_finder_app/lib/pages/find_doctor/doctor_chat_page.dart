import 'package:flutter/material.dart';
import 'dart:math'; // Import for generating random numbers

class DoctorChatPage extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorChatPage({Key? key, required this.doctor}) : super(key: key);

  @override
  _DoctorChatPageState createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  List<Map<String, String>> messages = []; // List to hold chat messages
  final TextEditingController _messageController = TextEditingController();

  // List of predefined responses from the doctor
  final List<String> doctorResponses = [
    "Hi, welcome Kevin!",
    "How may I help you?",
    "Is there anything specific you want to discuss?",
    "Please feel free to ask me anything.",
    "I'm here to help you.",
    "What concerns do you have today?",
  ];

  @override
  void initState() {
    super.initState();
    // Show the initial messages when the widget loads
    _sendInitialMessages();
  }

  void _sendInitialMessages() {
    setState(() {
      // Add the welcome message
      messages.add({
        'sender': 'doctor',
        'text': doctorResponses[0], // Welcome message
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract the doctor's name and image
    final doctorName = widget.doctor['name'] ?? 'Unknown Doctor';
    final doctorImage = widget.doctor['image'] ??
        'assets/images/doctor_image.png'; // Default image if none

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // White back icon
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  AssetImage(doctorImage), // Use AssetImage for doctor's image
            ),
            SizedBox(width: 8),
            Text(
              doctorName,
              style: const TextStyle(
                  fontSize: 18, color: Colors.white), // White text
            ),
          ],
        ),
        backgroundColor: const Color(0xFF008faf), // Customize as needed
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(messages[index], doctorImage);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, String> message, String doctorImage) {
    bool isUser = message['sender'] == 'user'; // Check if the sender is user
    final timestamp = DateTime.now()
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5); // Get the current time in HH:mm format

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(
                    doctorImage), // Use AssetImage for doctor's image
              ),
              SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width *
                      0.75), // Restrict max width
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[300] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message['text'] ?? '',
                style: TextStyle(color: Colors.black),
              ),
            ),
            if (isUser) ...[
              SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                    'https://via.placeholder.com/40'), // User's image URL
              ),
            ],
          ],
        ),
        // Display timestamp
        Padding(
          padding: const EdgeInsets.only(
              left: 60.0,
              right: 10.0,
              top: 2.0), // Adjust padding to align with messages
          child: Text(
            timestamp,
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        // Add user's message to the chat
        messages.add({
          'sender': 'user',
          'text': _messageController.text,
        });
      });

      // Introduce a delay before the doctor's response
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          // Select a random response from the doctor
          final randomResponse =
              doctorResponses[Random().nextInt(doctorResponses.length)];

          // Add doctor's response to the chat
          messages.add({
            'sender': 'doctor',
            'text': randomResponse,
          });
        });
      });

      _messageController.clear(); // Clear the input field
    }
  }
}
