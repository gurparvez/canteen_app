import 'package:canteen_app/providers/orders_provider.dart';
import 'package:canteen_app/providers/user_orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:canteen_app/screens/login/welcome_page.dart';
import 'package:provider/provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart'; // Import your WelcomeScreen
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => UserOrdersProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // could get the cart items before the app starts, but makes the startup time slow
    // Provider.of<CartProvider>(context, listen: false).fetchCartFromFirestore();
    return MaterialApp(
      title: 'University Canteen App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomeScreen(),
      routes: {
        // Define routes for LoginScreen and RegisterScreen
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
