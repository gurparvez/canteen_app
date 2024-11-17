import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:canteen_app/login/welcome_page.dart';
import 'package:provider/provider.dart';
import 'login/login_screen.dart';
import 'login/register_screen.dart'; // Import your WelcomeScreen
import 'menu/CartItem.dart';
import 'menu/CartProvider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Canteen App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(),
      routes: {
        // Define routes for LoginScreen and RegisterScreen
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
