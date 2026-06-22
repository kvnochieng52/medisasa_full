import 'package:xyvra_health/models/api_config.dart';
import 'package:xyvra_health/onboarding_page.dart';
import 'package:xyvra_health/pages/find_doctor/find_doctor_page.dart';
import 'package:flutter/material.dart';

class GreetingsWidget extends StatefulWidget {
  const GreetingsWidget({Key? key}) : super(key: key);

  @override
  State<GreetingsWidget> createState() => _GreetingsWidgetState();
}

class _GreetingsWidgetState extends State<GreetingsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  String username = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);
  }

  Future<void> _loadUserData() async {
    final userData = await ApiConfig.loadUserData();
    setState(() {
      username = userData?['name']?.split(' ')[0] ?? 'User';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  bool get isEvening {
    final hour = DateTime.now().hour;
    return hour >= 17 || hour < 6;
  }

  Color get cardColor {
    if (isEvening) {
      return const Color(0xFF1a1a2e);
    } else {
      return Colors.white;
    }
  }

  Color get textColor {
    return isEvening ? Colors.white : Colors.black;
  }

  LinearGradient get backgroundGradient {
    if (isEvening) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0f0f23),
          Color(0xFF16213e),
          Color(0xFF1a1a2e),
        ],
        stops: [0.0, 0.5, 1.0],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFfff4e6),
          Color(0xFFffe0b3),
          Colors.white,
        ],
        stops: [0.0, 0.3, 1.0],
      );
    }
  }

  Widget _buildTimeIcon() {
    if (isEvening) {
      // Moon with stars
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Stack(
              children: [
                // Moon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFf5f5dc),
                        Color(0xFFe6e6fa),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFf5f5dc).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Moon craters
                Positioned(
                  top: 8,
                  left: 12,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFd3d3d3).withOpacity(0.3),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 8,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFd3d3d3).withOpacity(0.3),
                    ),
                  ),
                ),
                // Twinkling stars
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final offset =
                          (_animationController.value + index * 0.3) % 1;
                      return Positioned(
                        top: 50 + index * 15,
                        left: 50 + index * 20,
                        child: Opacity(
                          opacity: (0.5 + 0.5 * (offset * 2 - 1).abs()),
                          child: Icon(
                            Icons.star,
                            size: 8 + index * 2,
                            color: Colors.yellow.withOpacity(0.8),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          );
        },
      );
    } else {
      // Animated sun
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFffd700),
                      Color(0xFFffa500),
                      Color(0xFFff8c00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFffd700).withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = getGreeting();

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Background icon
            Positioned(
              top: -10,
              left: -10,
              child: Opacity(
                opacity: 0.05,
                child: Transform.scale(
                  scale: 3,
                  child: _buildTimeIcon(),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Small time icon
                      _buildTimeIcon(),
                      const SizedBox(width: 16),
                      // Greeting text
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: '$greeting '),
                              TextSpan(
                                text: _isLoading ? '...' : username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isEvening
                                      ? const Color(0xFFffd700)
                                      : const Color(0xFF008faf),
                                ),
                              ),
                              const TextSpan(text: '!\\nHow can we help you today?'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FindDoctorPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008faf),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Need Help',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FindDoctorPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF008faf),
                            side: const BorderSide(color: Color(0xFF008faf)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Find Doctor',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }
}
