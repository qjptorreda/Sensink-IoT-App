import 'package:flutter/material.dart';
import 'package:flutter_application_1/sign_up.dart';
// Import your SignUpScreen file here if it is in a different file
// import 'sign_up_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Logic to handle Login
  void _handleLogin() {
    String email = _emailController.text;
    String password = _passwordController.text;

    // In a real app, you would check Firebase here.
    // For now, we simulate a "No Account" check.
    bool accountExists = false; // Replace with actual Firebase check

    if (!accountExists) {
      // Show error if account doesn't exist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No account found with this email. Please sign up first."),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Proceed with Login logic
      print("Logging in...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"), 
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            // Login Button
            ElevatedButton(
              onPressed: _handleLogin, 
              child: const Text("Login")
            ),

            const SizedBox(height: 10),

            // Navigation to Sign Up
            TextButton(
              onPressed: () {
                // This automatically moves the user to the Sign Up page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUp {
  const SignUp();
}