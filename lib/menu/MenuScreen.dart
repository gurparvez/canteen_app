import 'package:canteen_app/menu/CartScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'CartItem.dart';
import 'CartProvider.dart';

class MenuScreen extends StatelessWidget {
  final CollectionReference menuRef = FirebaseFirestore.instance.collection('menuItems');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Canteen Menu"), actions: [
        IconButton(onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartScreen()),
          );
        }, icon: Icon(Icons.shopping_cart))
      ],),
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
              var itemPrice = item['price'];
              var itemImage = item['image']; // Optional image field

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: itemImage != null
                      ? Image.network(itemImage, width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.fastfood, size: 50), // Placeholder icon if no image
                  title: Text(itemName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemDescription),
                      SizedBox(height: 4),
                      Text("₹$itemPrice", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final cartItem = CartItem(
                        id: item.id,
                        name: itemName,
                        price: itemPrice,
                      );

                      Provider.of<CartProvider>(context, listen: false).addToCart(cartItem);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$itemName added to cart")),
                      );
                    },
                    child: Text("Add to Cart"),
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
