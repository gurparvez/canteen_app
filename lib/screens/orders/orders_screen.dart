import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canteen_app/providers/orders_provider.dart';
import 'package:canteen_app/screens/orders/all_orders.dart';
import 'package:canteen_app/screens/orders/stocks_screen.dart';
import 'package:canteen_app/screens/users/user_management.dart';
import 'package:canteen_app/utils/supabase_client.dart';

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
    _checkAuth();
    _fetchOrders();
  }

  Future<void> _checkAuth() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
        return;
      }
    }

    // Check if user is staff
    try {
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user!.id)
          .single();

      if (userData['role'] != 'staff') {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Provider.of<OrdersProvider>(context, listen: false).fetchOrders();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch orders error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch orders. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final orders = ordersProvider.todayOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Orders"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StocksScreen()),
              );
            },
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllOrders()),
              );
            },
            icon: const Icon(Icons.list),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              );
            },
            icon: const Icon(Icons.supervisor_account_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No orders available"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isCompleted = order.status == 'Completed';
          final isCancelled = order.status == 'Cancelled';

          return Opacity(
            opacity:
            isCompleted || isCancelled ? 0.5 : 1.0, // Fade effect
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  "Order by ${order.userName}",
                  style: TextStyle(
                    color: isCompleted || isCancelled
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.orderItems.map((item) {
                      return Text(
                        "${item['name']} x ${item['quantity']} - ₹${item['price'] * item['quantity']}",
                        style: TextStyle(
                          color: isCompleted || isCancelled
                              ? Colors.grey
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8.0),
                    Text(
                      "Total: ₹${order.totalPrice}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted || isCancelled
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    Text(
                      "Status: ${order.status}",
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green
                            : isCancelled
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
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
                      value: 'Pending',
                      child: Text("Mark as Pending"),
                    ),
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
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchOrders,
        tooltip: 'Refresh Orders',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
