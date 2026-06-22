import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:xyvra_health/app_router.dart';
import 'package:xyvra_health/auth_service.dart';
import 'package:xyvra_health/services/payment_deep_link_service.dart';
import 'package:xyvra_health/utils/router_error_interceptor.dart';
import 'package:flutter/material.dart';

Map<int, Color> colorSwatch = {
  50: const Color.fromRGBO(0, 143, 175, .1),
  100: const Color.fromRGBO(0, 143, 175, .2),
  200: const Color.fromRGBO(0, 143, 175, .3),
  300: const Color.fromRGBO(0, 143, 175, .4),
  400: const Color.fromRGBO(0, 143, 175, .5),
  500: const Color.fromRGBO(0, 143, 175, .6),
  600: const Color.fromRGBO(0, 143, 175, .7),
  700: const Color.fromRGBO(0, 143, 175, .8),
  800: const Color.fromRGBO(0, 143, 175, .9),
  900: const Color.fromRGBO(0, 143, 175, 1.0),
};

MaterialColor customSwatch = MaterialColor(0xFF008faf, colorSwatch);

void main() async {
  try {
    print('App: Starting application...');
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize router error interceptor to catch Go Router canonicalUri errors
    print('App: Initializing RouterErrorInterceptor...');
    RouterErrorInterceptor.initialize();

    // Initialize auth service and wait for completion
    print('App: Initializing AuthService...');
    await AuthService().init();
    print(
        'App: AuthService initialized. Initial auth state: ${AuthService().isAuthenticated}');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('App: Fatal error during initialization: $e');
    print('App: Stack trace: $stackTrace');

    // Try to run a minimal app in case of error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Application Error', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text('Error: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  late final StreamSubscription<Uri> _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'xyvrahealth') {
        PaymentDeepLinkService().handle(uri);
      }
    });
  }

  @override
  void dispose() {
    _linkSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Doc Finder',
      debugShowCheckedModeBanner: false,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routerDelegate: AppRouter.router.routerDelegate,
      theme: ThemeData(
        primarySwatch: customSwatch,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF008faf),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.white,
          backgroundColor: Color(0xFF008faf),
        ),
      ),
    );
  }
}
