import 'package:canteen_app/models/cart_item.dart';
import 'package:canteen_app/providers/cart_provider.dart';
import 'package:canteen_app/screens/menu/cart_screen.dart';
import 'package:canteen_app/screens/menu/user_orders.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class MenuScreen extends StatefulWidget {
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final CollectionReference menuRef =
      FirebaseFirestore.instance.collection('menuItems');

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
        _loadingStates[cartItem.id] = false; // Stop loading for this item
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
      body: StreamBuilder<QuerySnapshot>(
        stream: menuRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No menu items available"));
          }

          // List of menu items
          final menuItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              // Access each item’s data
              var item = menuItems[index];
              var itemName = item['name'];
              var itemDescription = item['description'];
              var itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
              var itemImage = item['image'];

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: itemImage != null
                      ? Image.network(
                          itemImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.fastfood,
                          size: 50,
                        ), // Placeholder icon if no image
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
                        id: item.id,
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
