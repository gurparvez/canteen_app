import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => _UserOrdersState();
}

class _UserOrdersState extends State<UserOrders> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Orders")),
        body: const Center(
          child: Text("Please log in to view your orders."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't placed any orders yet."),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderItems = order['orderItems'] as List<dynamic>;
              final status = order['status'];
              final totalPrice = order['totalPrice'];
              final timestamp = (order['timestamp'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: status == "Completed"
                    ? Colors.green.shade100
                    : status == "Cancelled"
                        ? Colors.red.shade100
                        : null,
                child: ListTile(
                  title: Text(
                    "Order Total: ₹$totalPrice",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: $status"),
                      Text("Date: ${timestamp.toString()}"),
                      const SizedBox(height: 8),
                      ...orderItems.map((item) {
                        return Text(
                          "${item['name']} - ₹${item['price']} x ${item['quantity']}",
                        );
                      }).toList(),
                    ],
                  ),
                  trailing: status == "Completed"
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : status == "Cancelled"
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : const Icon(Icons.hourglass_empty,
                              color: Colors.orange),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
