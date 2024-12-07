import 'package:canteen_app/utils/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoadUserSession extends StatefulWidget {
  const LoadUserSession({super.key});

  @override
  State<LoadUserSession> createState() => _LoadUserSessionState();
}

class _LoadUserSessionState extends State<LoadUserSession> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getSession();
    });
  }

  final storage = const FlutterSecureStorage();

  void _getSession() async {
    final storedToken = await storage.read(
      key: 'refresh_token',
      webOptions: const WebOptions(),
      aOptions: const AndroidOptions(),
      iOptions: const IOSOptions(),
    );

    debugPrint(storedToken);

    if (storedToken == null) {
      // If no token is stored, redirect to the welcome page
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          "/welcome",
              (route) => false,
        );
      }
      return;
    }

    try {
      final response = await supabase.auth.setSession(storedToken);

      if (response.session != null) {
        // Save the updated session in storage
        await storage.write(
          key: 'refresh_token',
          value: supabase.auth.currentSession!.refreshToken,
        );
      } else {
        throw Exception("Session could not be restored");
      }
    } catch (e) {
      debugPrint("Error restoring session: $e");
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          "/welcome",
              (route) => false,
        );
      }
      return;
    }

    // Proceed with your navigation logic
    final session = supabase.auth.currentSession!;
    final userId = session.user.id;

    final userData =
        await supabase.from('users').select().eq('id', userId).single();

    if (userData["role"] == "staff") {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          "/orders",
              (route) => false,
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          "/menu",
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
