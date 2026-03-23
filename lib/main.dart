import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Added Firestore import
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:google_sign_in_web/web_only.dart' as web show renderButton;
import 'home.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
// ignore: depend_on_referenced_packages
import "package:flutter_facebook_auth/flutter_facebook_auth.dart";

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: '3303649073117124',
      cookie: true,
      xfbml: true,
      version: "v18.0",
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
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _timer;
  bool _canResendEmail = true;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() {
        _canResendEmail = false;
        _resendCountdown = 60;
      });
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCountdown == 0) {
          setState(() => _canResendEmail = true);
          timer.cancel();
        } else {
          setState(() => _resendCountdown--);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email resent!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null) {
          if (!user.emailVerified) {
            _timer?.cancel();
            _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
              await FirebaseAuth.instance.currentUser?.reload();
              if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
                timer.cancel();
                if (mounted) setState(() {}); 
              }
            });
            return Scaffold(
              backgroundColor: Colors.black.withOpacity(0.05),
              body: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                  ),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_unread_rounded, size: 60, color: Colors.orange),
                      ),
                      const SizedBox(height: 24),
                      const Text("Verify Your Email", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text("Check ${user.email} to continue.", textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 32),
                      _buildAwesomeButton(
                        label: _canResendEmail ? "RESEND EMAIL" : "RESEND IN ${_resendCountdown}s",
                        onPressed: _canResendEmail ? _resendVerificationEmail : () {},
                        color: _canResendEmail ? const Color(0xFF008996) : Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Use a different email"))
                    ],
                  ),
                ),
              ),
            );
          }
          // Check if user is newly created to land them on the profile/settings tab
          final bool isNewUser = user.metadata.creationTime == user.metadata.lastSignInTime;
          return HomeScreen(initialIndex: isNewUser ? 2 : 0);
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController(); 
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUpMode = true; 
  bool _agreeToTerms = false;
  bool _obscureText = true; 
  
  late GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? '837308570802-fhcg9srv2gh2ufqh24vd6nk0oo3l9lj7.apps.googleusercontent.com' : null,
    );
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) await _linkGoogleToFirebase(account);
    });
    if (kIsWeb) { _googleSignIn.signInSilently(); }
  }

  Future<void> _processAuth() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }
    if (_isSignUpMode) {
      if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
        _showError("First and Last name are required");
        return;
      }
      if (_passController.text != _confirmPassController.text) {
        _showError("Passwords do not match");
        return;
      }
      if (!_agreeToTerms) {
        _showError("Please agree to the Terms & Conditions");
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignUpMode) {
        // 1. Create User in Firebase Auth
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        // 2. NEW: Save details to Firestore "users" collection
        if (cred.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'firstName': _firstNameController.text.trim(),
            'middleName': _middleNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'uid': cred.user!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        await cred.user?.sendEmailVerification();
        if (mounted) _showSweetWelcome(cred.user!.email!);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication Failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final facebookInstance = FacebookAuth.instance;
      final LoginResult result = await facebookInstance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      _showError("Facebook Login Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSweetWelcome(String email) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF008996), size: 60),
                ),
                const SizedBox(height: 20),
                const Text("Welcome to SenSink!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildAwesomeButton(
                  label: "GOT IT!", 
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isSignUpMode = false);
                  }, 
                  color: const Color(0xFF008996)
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _linkGoogleToFirebase(GoogleSignInAccount googleUser) async {
    final auth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);
    
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(cred);
    
    // Check if it's the first time they sign in with Google to save their name
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': googleUser.displayName ?? '',
        'lastName': '',
        'email': googleUser.email,
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blueColor = const Color(0xFF008996); 

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue, size: 70),
                const Text("SenSink", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                if (_isSignUpMode) ...[
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: _firstNameController, label: "First Name", icon: Icons.person, isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(controller: _middleNameController, label: "Middle Name", icon: Icons.person_outline, isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _lastNameController, label: "Last Name", icon: Icons.person, isDark: isDark),
                  const SizedBox(height: 16),
                ],
                _buildTextField(controller: _emailController, label: "Email Address", icon: Icons.email, isDark: isDark),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passController, 
                  label: "Password", 
                  icon: Icons.lock, 
                  isDark: isDark, 
                  obscure: _obscureText,
                  suffix: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
                if (!_isSignUpMode) 
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if(_emailController.text.isNotEmpty) {
                          FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
                          _showError("Reset link sent!");
                        }
                      }, 
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                if (_isSignUpMode) ...[
                  const SizedBox(height: 16),
                  _buildTextField(controller: _confirmPassController, label: "Confirm Password", icon: Icons.lock_reset, isDark: isDark, obscure: _obscureText),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _agreeToTerms,
                    onChanged: (v) => setState(() => _agreeToTerms = v!),
                    title: const Text("I agree to Terms & Conditions", style: TextStyle(fontSize: 12)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                const SizedBox(height: 24),
                _buildAwesomeButton(
                  label: _isSignUpMode ? "CREATE ACCOUNT" : "SIGN IN",
                  onPressed: _processAuth,
                  isLoading: _isLoading,
                  color: blueColor,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                  child: Text(_isSignUpMode ? "Already have an account? Sign In" : "New user? Sign Up"),
                ),
                const Divider(height: 40),
                
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 300, 
                    child: Column(
                      children: [
                        if (kIsWeb) 
                          web.renderButton()
                        else 
                          _buildSocialButton(
                            label: "Continue with Google",
                            icon: Icons.account_circle,
                            color: Colors.blue,
                            onPressed: () async {
                              final user = await _googleSignIn.signIn();
                              if (user != null) _linkGoogleToFirebase(user);
                            },
                          ),
                        const SizedBox(height: 12),
                        _buildSocialButton(
                          label: "Continue with Facebook",
                          icon: Icons.facebook,
                          color: const Color(0xFF1877F2),
                          onPressed: _signInWithFacebook,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// UI Helper Methods (unchanged)
Widget _buildSocialButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: color),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      side: const BorderSide(color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool isDark,
  bool obscure = false,
  Widget? suffix,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: Colors.blue),
      suffixIcon: suffix,
      labelText: label,
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}

Widget _buildAwesomeButton({
  required String label,
  required VoidCallback onPressed,
  required Color color,
  bool isLoading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}