import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canteen_app/providers/orders_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });
    await Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final orders = ordersProvider.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text("No orders available"))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text("Order by ${order.userName}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...order.orderItems.map((item) {
                              return Text(
                                "${item['name']} x ${item['quantity']} - ₹${item['price'] * item['quantity']}",
                              );
                            }).toList(),
                            const SizedBox(height: 8.0),
                            Text(
                              "Total: ₹${order.totalPrice}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Status: ${order.status}"),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (newStatus) {
                            ordersProvider.updateOrderStatus(
                              order.id,
                              newStatus,
                            );
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Completed',
                              child: Text("Mark as Completed"),
                            ),
                            const PopupMenuItem(
                              value: 'Cancelled',
                              child: Text("Mark as Cancelled"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
