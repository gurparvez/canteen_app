import 'package:flutter/material.dart';
import 'package:canteen_app/utils/supabase_client.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => _UserOrdersState();
}

class _UserOrdersState extends State<UserOrders> {
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "You haven't placed any orders yet.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderItems = order['order_items'] as List<dynamic>;
              final status = order['status'] as String;
              final totalPrice = order['total_price'] as num;
              final timestamp = DateTime.parse(order['created_at']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: status == "completed"
                    ? Colors.green.shade100
                    : status == "cancelled"
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
                      Text("Status: ${status[0].toUpperCase()}${status.substring(1)}"),
                      Text(
                        "Date: ${timestamp.toLocal().toString().split('.')[0]}",
                      ),
                      const SizedBox(height: 8),
                      ...orderItems.map((item) {
                        return Text(
                          "${item['name']} - ₹${item['price']} x ${item['quantity']}",
                        );
                      }).toList(),
                    ],
                  ),
                  trailing: status == "completed"
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : status == "cancelled"
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : const Icon(Icons.hourglass_empty, color: Colors.orange),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
