import 'package:canteen_app/screens/login/login_staff_screen.dart';
import 'package:canteen_app/screens/menu/menu_screen.dart';
import 'package:canteen_app/screens/orders/orders_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:canteen_app/firebase_options.dart';
import 'package:canteen_app/providers/items_provider.dart';
import 'package:canteen_app/providers/orders_provider.dart';
import 'package:canteen_app/providers/user_orders_provider.dart';
import 'package:canteen_app/providers/users_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:canteen_app/screens/login/welcome_page.dart';
import 'package:provider/provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'providers/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: migrate the entire app to supabase.
// push notifications require to upgrade the firebase project

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env["SUPABASE_URL"] ?? "",
    anonKey: dotenv.env["SUPABASE_ANON_KEY"] ?? "",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => UserOrdersProvider()),
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/login-staff': (context) => const LoginStaffScreen(),
        '/register': (context) => const RegisterScreen(),
        "/menu": (context) => MenuScreen(),
        "/orders": (context) => const OrdersScreen(),
      },
    );
  }
}
