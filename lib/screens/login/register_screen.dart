import 'package:canteen_app/screens/menu/menu_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> registerUser() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user?.uid;

      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'email': _emailController.text.trim(),
          'name': _emailController.text.trim().split('@')[0],
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint("User registered and data saved to Firestore");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen()),
      );
    } catch (e) {
      debugPrint("Registration error: $e");
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration failed!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerUser,
              child: const Text("Register"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text("Go to Login"),
            ),
          ],
        ),
      ),
    );
  }
}
