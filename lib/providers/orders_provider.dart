import 'package:canteen_app/models/order_item.dart';
import 'package:canteen_app/utils/supabase_client.dart';
import 'package:flutter/material.dart';

class OrdersProvider with ChangeNotifier {
  List<OrderItem> _orders = [];
  List<OrderItem> _todayOrders = [];

  List<OrderItem> get orders => _orders;
  List<OrderItem> get todayOrders => _todayOrders;

  Future<void> fetchOrders() async {
    try {
      final snapshot = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final now = DateTime.now();
      bool isToday(DateTime time) =>
          time.year == now.year && time.month == now.month && time.day == now.day;

      List<OrderItem> fetchedOrders = snapshot.map<OrderItem>((data) {
        return OrderItem(
          id: data['id'],
          userName: data['user_name'],
          orderItems: (data['order_items'] as List).cast<Map<String, dynamic>>(),
          totalPrice: (data['total_price'] as num).toDouble(),
          status: data['status'],
          timestamp: DateTime.parse(data['created_at']),
        );
      }).toList();

      _orders = fetchedOrders;
      _todayOrders = fetchedOrders.where((order) => isToday(order.timestamp)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus.toLowerCase()})
          .eq('id', orderId);

      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      final todayOrderIndex = _todayOrders.indexWhere((order) => order.id == orderId);

      if (orderIndex != -1) {
        _orders[orderIndex] = OrderItem(
          id: _orders[orderIndex].id,
          userName: _orders[orderIndex].userName,
          orderItems: _orders[orderIndex].orderItems,
          totalPrice: _orders[orderIndex].totalPrice,
          status: newStatus.toLowerCase(),
          timestamp: _orders[orderIndex].timestamp,
        );
      }

      if (todayOrderIndex != -1) {
        _todayOrders[todayOrderIndex] = OrderItem(
          id: _todayOrders[todayOrderIndex].id,
          userName: _todayOrders[todayOrderIndex].userName,
          orderItems: _todayOrders[todayOrderIndex].orderItems,
          totalPrice: _todayOrders[todayOrderIndex].totalPrice,
          status: newStatus.toLowerCase(),
          timestamp: _todayOrders[todayOrderIndex].timestamp,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }
}
