import 'package:flutter/material.dart';
import 'package:marketplace_app/screens/auth/login_screen.dart';
// import 'package:flutter/rendering.dart'; // Commented out: Used for debugging layout, not needed for production

void main() {
  // debugPaintSizeEnabled = true; // Commented out: Used for debugging layout boundaries
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace App', // Application title
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // Defines the primary color palette
        visualDensity: VisualDensity
            .adaptivePlatformDensity, // Adapts UI density based on platform
      ),
      home: const LoginScreen(), // Sets LoginScreen as the initial screen
      debugShowCheckedModeBanner:
          false, // Hides the debug banner in the top right corner
    );
  }
}
