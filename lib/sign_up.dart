import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Blue gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Sign Up", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Please fill in this form to create an account!", 
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const Divider(height: 40, thickness: 1),

                    // First Name and Last Name in one row
                    Row(
                      children: [
                        Expanded(child: _buildTextField("First Name", _firstNameController)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextField("Last Name", _lastNameController)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField("Email", _emailController),
                    const SizedBox(height: 15),
                    _buildTextField("Password", _passController, isPassword: true),
                    const SizedBox(height: 15),
                    _buildTextField("Confirm Password", _confirmPassController, isPassword: true),
                    
                    const SizedBox(height: 15),

                    // Terms and Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (val) => setState(() => _acceptTerms = val!),
                        ),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: "I accept the ",
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                              children: [
                                TextSpan(text: "Terms of Use", style: TextStyle(color: Colors.blue)),
                                TextSpan(text: " & "),
                                TextSpan(text: "Privacy Policy", style: TextStyle(color: Colors.blue)),
                              ]
                            )
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),

                    // Blue Button
                    SizedBox(
                      width: 160,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate() && _acceptTerms) {
                            // Proceed with Sign Up Logic
                          }
                        },
                        child: const Text("Sign Up", 
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // Bottom navigation bar to go back to Login
      bottomNavigationBar: Container(
        height: 60,
        color: const Color(0xFF1976D2),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text("Already have an account? Login here.", 
              style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}