import 'package:xyvra_health/welcome/welcome.dart';
import 'package:onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

final onboardingPagesList = [
  SizedBox(
    height: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          width: 0.0,
          color: background,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 280, // Further reduced height for the image
            padding: const EdgeInsets.symmetric(
                horizontal: 15.0), // Adjusted padding
            child: Image.asset(
              'assets/images/doctor.png',
            ),
          ),
          const SizedBox(
            height: 140, // Further reduced height for content section
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 6), // Reduced padding
                    child: Text(
                      'WELCOME TO MEDISASA',
                      style: pageTitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 3), // Further reduced padding
                    child: Text(
                      'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
                      style: pageInfoStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  SizedBox(
    height: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          width: 0.0,
          color: background,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 280, // Further reduced height for the image
            padding: const EdgeInsets.symmetric(
                horizontal: 15.0), // Adjusted padding
            child: Image.asset(
              'assets/images/doctor.png',
            ),
          ),
          const SizedBox(
            height: 140, // Further reduced height for content section
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 6), // Reduced padding
                    child: Text(
                      'ORDER MEDICINE ONLINE',
                      style: pageTitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 3), // Further reduced padding
                    child: Text(
                      'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                      style: pageInfoStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  SizedBox(
    height: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          width: 0.0,
          color: background,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 280, // Further reduced height for the image
            padding: const EdgeInsets.symmetric(
                horizontal: 15.0), // Adjusted padding
            child: Image.asset(
              'assets/images/doctor.png',
            ),
          ),
          const SizedBox(
            height: 140, // Further reduced height for content section
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 6), // Reduced padding
                    child: Text(
                      'BOOK APPOINTMENTS',
                      style: pageTitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 3), // Further reduced padding
                    child: Text(
                      'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                      style: pageInfoStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late int index;
  final activePainter = Paint();
  final inactivePainter = Paint();

  @override
  void initState() {
    super.initState();
    index = 0;
    activePainter.color = Colors.white;
    activePainter.strokeWidth = 1;
    activePainter.strokeCap = StrokeCap.round;
    activePainter.style = PaintingStyle.fill;

    inactivePainter.color = pageImageColor;
    inactivePainter.strokeWidth = 1;
    inactivePainter.strokeCap = StrokeCap.round;
    inactivePainter.style = PaintingStyle.stroke;
  }

  SizedBox get _signupButton {
    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: defaultProceedButtonBorderRadius,
        color: defaultProceedButtonColor,
        child: InkWell(
          borderRadius: defaultProceedButtonBorderRadius,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomePage(),
              ),
            );
          },
          child: const SizedBox(
            height: 50.0, // Reduced button height
            child: Center(
              child: Text(
                'Continue',
                style: defaultProceedButtonTextStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: Column(
          children: [
            // Full-width background for logo and title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50.0), // Reduced padding
              color: const Color(
                  0xFF008faf), // Background color for the entire section
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_outline.png', // Path to your logo
                    height: 90, // Adjusted the height of the logo
                  ),
                  const SizedBox(
                      height: 4), // Reduced space between logo and text
                  const Text(
                    'MediSasa',
                    style: TextStyle(
                      fontSize: 16, // Adjusted text size
                      color: Colors.white,
                      fontWeight: FontWeight.bold, // White text color
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Onboarding(
                swipeableBody: onboardingPagesList,
                startIndex: 0,
                onPageChanges: (_, __, currentIndex, sd) {
                  index = currentIndex;
                },
                buildFooter: (context, dragDistance, pagesLength, currentIndex,
                    setIndex, sd) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      border: Border.all(
                        width: 0.0,
                        color: background,
                      ),
                    ),
                    child: ColoredBox(
                      color: background,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 20), // Adjusted footer padding
                        child: Column(
                          children: [
                            // Center-aligned indicators
                            Container(
                              padding: const EdgeInsets.only(
                                  bottom: 8), // Reduced padding
                              alignment: Alignment.center,
                              child: Indicator<TrianglePainter>(
                                painter: TrianglePainter(
                                  currentPageIndex: currentIndex,
                                  pagesLength: pagesLength,
                                  netDragPercent: dragDistance,
                                  activePainter: activePainter,
                                  inactivePainter: inactivePainter,
                                  slideDirection: sd,
                                  showAllActiveIndicators: false,
                                ),
                              ),
                            ),
                            // Signup button with full width
                            Padding(
                              padding: const EdgeInsets.only(top: 30.0),
                              child: _signupButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
