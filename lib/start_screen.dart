import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/main.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home.dart' hide themeNotifier;
import 'firebase_options.dart';

// 1. THIS MUST BE OUTSIDE ALL CLASSES
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// 2. Then your MyApp class follows
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Adaptive colors based on the current theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // --- Decorative Background Elements ---
          Positioned(top: 150, left: 40, child: _buildChipIcon(isDark)),
          Positioned(bottom: 180, right: 60, child: _buildChipIcon(isDark)),
          
          // Custom painting for the node links
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            painter: NodeLinkPainter(isDark: isDark),
          ),

          // --- Top Actions (Settings & Theme Toggle) ---
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                Icon(Icons.settings, color: isDark ? Colors.blue.shade300 : Colors.blue),
                const SizedBox(width: 10),
                _buildThemeToggle(context),
              ],
            ),
          ),

          // --- Central Branding Section ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Decorative Circle
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Inner Logo Circle
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF333333), // Consistent Dark Brand Color
                        border: Border.all(color: Colors.blue, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            const Center(
                              child: Text(
                                "SenSink",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Wave/Water decorative element at the bottom of the logo
                            Positioned(
                              bottom: 0,
                              child: Container(
                                height: 60,
                                width: 190,
                                color: Colors.blue.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                
                // --- GET STARTED BUTTON ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigator.pushReplacement ensures the user can't "Go Back" to the start screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthGate()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "GET STARTED",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Bottom Version Text ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                "Version 1.0.0", 
                style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey, fontSize: 12)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipIcon(bool isDark) {
    return Icon(
      Icons.memory, 
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3), 
      size: 45
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;
        
        return GestureDetector(
          onTap: () {
            // Toggles the global notifier in main.dart
            themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                // Light Mode Icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: !isDark ? Colors.blue : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wb_sunny_outlined, 
                    color: !isDark ? Colors.white : Colors.grey, size: 14),
                ),
                const SizedBox(width: 8),
                // Dark Mode Icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.nightlight_round_outlined, 
                    color: isDark ? Colors.white : Colors.grey, size: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Background Painter for the tech-node aesthetic
class NodeLinkPainter extends CustomPainter {
  final bool isDark;
  NodeLinkPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1.5;

    final dotPaint = Paint()..color = isDark ? Colors.blue.shade300 : Colors.blue;

    // Draw some stylized lines and nodes
    canvas.drawLine(Offset(size.width * 0.7, size.height * 0.3), Offset(size.width * 0.8, size.height * 0.25), paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.25), 8, dotPaint);

    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.6), Offset(size.width * 0.1, size.height * 0.6), paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.6), 10, dotPaint);

    canvas.drawLine(Offset(size.width * 0.4, size.height * 0.6), Offset(size.width * 0.2, size.height * 0.8), paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 10, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}