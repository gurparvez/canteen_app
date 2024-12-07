import 'package:canteen_app/models/cart_item.dart';
import 'package:canteen_app/providers/cart_provider.dart';
import 'package:canteen_app/screens/menu/cart_screen.dart';
import 'package:canteen_app/screens/menu/user_orders.dart';
import 'package:canteen_app/screens/profile/profile_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canteen_app/utils/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuScreen extends StatefulWidget {
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    _updateFcmToken();
  }

  Future<void> _updateFcmToken() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    }
    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();

        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          await _setFcmToken(fcmToken);
        }
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await _setFcmToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${notification.title} ${notification.body}"),
          ),
        );
      }
    });
  }

  Future<void> _setFcmToken(String fcmToken) async {
    try {
      await supabase
        .from('users')
        .update({'fcm_token': fcmToken})
        .eq('id', supabase.auth.currentUser!.id);
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getMenuItems() {
    return supabase.from('menu_items').stream(primaryKey: ['id']).order('name');
  }

  Map<String, bool> _loadingStates = {};

  Future<void> addItemToCart(BuildContext context, CartItem cartItem) async {
    setState(() {
      _loadingStates[cartItem.id] = true;
    });

    try {
      await Provider.of<CartProvider>(context, listen: false)
          .addToCart(cartItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${cartItem.name} added to cart")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add ${cartItem.name} to cart")),
      );
    } finally {
      setState(() {
        _loadingStates[cartItem.id] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Canteen Menu"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserOrders()),
              );
            },
            icon: const Icon(Icons.list),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
            icon: const Icon(Icons.shopping_cart),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No menu items available"));
          }

          final menuItems = snapshot.data!;

          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final itemName = item['name'] as String;
              final itemDescription = item['description'] as String;
              final itemPrice = (item['price'] as num).toDouble();
              final itemImage = item['image'] as String?;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: itemImage != null
                      ? Image.network(
                          itemImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.fastfood,
                              size: 50,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.fastfood,
                          size: 50,
                        ),
                  title: Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemDescription),
                      const SizedBox(height: 4),
                      Text(
                        "₹ $itemPrice",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final cartItem = CartItem(
                        id: item["id"],
                        name: itemName,
                        price: itemPrice,
                        quantity: 1,
                      );

                      Provider.of<CartProvider>(context, listen: false)
                          .addToCart(cartItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$itemName added to cart")),
                      );
                    },
                    child: const Text("Add to Cart"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
