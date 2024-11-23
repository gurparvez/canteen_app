import 'package:canteen_app/providers/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  void fetchOrders() async {
    List allOrders = Provider.of<OrdersProvider>(context, listen: false).orders;

    if (allOrders.isNotEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      await Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to login. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final orders = ordersProvider.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Orders"),
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
                            }),
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
