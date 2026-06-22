import 'package:flutter/material.dart';

class CallWidget extends StatefulWidget {
  final String doctorName;
  final String doctorImage;

  const CallWidget({
    Key? key,
    required this.doctorName,
    required this.doctorImage,
  }) : super(key: key);

  @override
  _CallWidgetState createState() => _CallWidgetState();
}

class _CallWidgetState extends State<CallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize the Animation Controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation

    // Create a shaking animation
    _animation = Tween<double>(begin: -10, end: 10).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated shaking effect for the doctor's image
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_animation.value, 0), // Shake horizontally
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(widget.doctorImage),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Calling ${widget.doctorName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // End Call Button
            Container(
              decoration: BoxDecoration(
                color: Colors.red, // Background color for the end call button
                shape: BoxShape.circle, // Make it circular
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.call_end,
                  size: 40,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Handle end call logic
                  Navigator.pop(context); // End the call
                },
                padding: const EdgeInsets.all(16), // Padding for the button
                splashRadius: 30, // Splash radius
              ),
            ),
          ],
        ),
      ),
    );
  }
}
