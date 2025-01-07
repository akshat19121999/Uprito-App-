import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to BLEScanScreen after 5 seconds
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/ble_scan');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Opacity
          Opacity(
            opacity: 0.3, // Adjust the opacity of the background image
            child: Image.asset(
              'assets/background2.png', // Add your background image to the assets folder
              fit: BoxFit.cover,
            ),
          ),
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Logo
                Image.asset(
                  'assets/logo.png', // Add your logo to the assets folder
                  height: 400.0,
                  width: 400.0,
                ),
                const SizedBox(height: 20),
                // Animated Text Kit
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      'UPRIGHT POSTURE REMINDER, INITIATION & TELE PHYSIOTHERAPY FOR OLDER ADULTS',
                      textAlign: TextAlign.center,
                      textStyle: const TextStyle(
                        color: Color.fromRGBO(114, 3, 3, 1),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                      speed: const Duration(milliseconds: 50), // Slower speed
                    ),
                  ],
                  isRepeatingAnimation: true,
                  repeatForever: true,
                  onTap: () {
                    print("Tap Event");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
