import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue,
      ),
      home: const AuthGate(),
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
        if (snapshot.hasData) {
          return const HomeScreen();
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
  
  VoidCallback? get _signInWithEmail => null;

 Future<void> _signInWithGoogle() async {
  try {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    await FirebaseAuth.instance.signInWithPopup(googleProvider);
  } catch (e) {
    _showError("Google Login Failed: $e");
  }
}


  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Text("SenSink Login", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(
                controller: _passController, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signInWithEmail,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Sign In"),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text("Continue with Google"),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                child: const Text("Create an account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on GoogleSignIn {
  Future<GoogleSignInAccount?> signIn() async {}
}

extension on GoogleSignInAuthentication {
  String? get accessToken => null;
}


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passController.text.trim(),
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SenSink Home"),
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(radius: 50, backgroundImage: NetworkImage(user!.photoURL!)),
            const SizedBox(height: 20),
            Text("Welcome, ${user?.displayName ?? 'User'}!", style: const TextStyle(fontSize: 22)),
            Text("${user?.email}"),
          ],
        ),
      ),
    );
  }
}