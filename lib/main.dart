import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'home.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SenSink',
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFFF2F2F2),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home:
              const AuthGate(), 
        );
      },
    );
  }
}

// --- AUTH GATE ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Only allow entry if user exists AND email is verified
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );

      // Verify if email is confirmed
      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        _showError(
          "Email not verified. A new link has been sent to your inbox.",
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login Failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showError("Please enter your email address first.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      _showSuccess("Password reset link sent! Check your inbox.");
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Error sending reset email.");
    } catch (e) {
      _showError("An unexpected error occurred.");
    }
  }

Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; 

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
    // Navigate to Dashboard after success
  } catch (e) {
    print("Error during sign-in: $e");
  }
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 60),
              const SizedBox(height: 10),
              Text(
                "SenSink",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _emailController,
                label: "Email",
                icon: Icons.email_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passController,
                label: "Password",
                icon: Icons.lock_outline,
                isDark: isDark,
                obscure: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _buildAwesomeButton(
                label: "SIGN IN",
                onPressed: _signInWithEmail,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.network(
                  'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                  height: 20,
                  width: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.login, size: 18),
                ),
                label: Text(
                  "Continue with Google",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New here?"),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    ),
                    child: const Text(
                      "Create Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Future<void> {
  Future<GoogleSignInAccount?> signIn() async {
    return null;
  }
}

extension on GoogleSignIn {
  Future<GoogleSignInAccount?> signIn() async {
    return null;
  }
}

extension on GoogleSignInAuthentication {
  String? get accessToken => null;
}

class GoogleLogin {
  Future<GoogleSignInAccount?> signIn() async {
    return null;
  }
}

// --- SIGN UP SCREEN ---
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and Password are required")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
          );

      // SEND VERIFICATION EMAIL
      await userCredential.user!.sendEmailVerification();

      await fs.FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'address': _addressController.text.trim(),
            'phone': _phoneController.text.trim(),
            'uid': userCredential.user!.uid,
            'createdAt': fs.FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Account created! Please verify your email before logging in.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Sign out so they must log in again after verifying
        await FirebaseAuth.instance.signOut();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sign Up —",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(
              controller: _nameController,
              label: "Name",
              icon: Icons.person_outline,
              isDark: isDark,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _usernameController,
              label: "Username",
              icon: Icons.alternate_email,
              isDark: isDark,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _passController,
              label: "Password",
              icon: Icons.lock_outline,
              isDark: isDark,
              obscure: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _addressController,
              label: "Address",
              icon: Icons.home_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _phoneController,
              label: "Phone Number",
              icon: Icons.phone_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 30),
            _buildAwesomeButton(
              label: "SIGN UP",
              onPressed: _registerUser,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- SHARED UI HELPERS ---
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool isDark,
  bool obscure = false,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blue, size: 20),
      labelText: label,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    ),
  );
}

Widget _buildAwesomeButton({
  required String label,
  required VoidCallback onPressed,
  bool isLoading = false,
}) {
  return Container(
    width: double.infinity,
    height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: const LinearGradient(colors: [Colors.blue, Color(0xFF00D2FF)]),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}
