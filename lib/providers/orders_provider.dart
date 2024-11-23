import 'package:canteen_app/models/order_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<OrderItem> _orders = [];
  List<OrderItem> _todayOrders = [];

  List<OrderItem> get orders => _orders;
  List<OrderItem> get todayOrders => _todayOrders;

  Future<void> fetchOrders() async {
    final snapshot = await _firestore
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    final now = DateTime.now();
    bool isToday(DateTime time) =>
        time.year == now.year && time.month == now.month && time.day == now.day;

    // Map Firestore documents to OrderItem objects
    List<OrderItem> fetchedOrders = snapshot.docs
        .map((doc) => OrderItem.fromMap(doc.id, doc.data()))
        .toList();

    _orders = fetchedOrders;

    // Filter only today's orders
    List<OrderItem> todayOrders =
        fetchedOrders.where((order) => isToday(order.timestamp)).toList();

    // Sort the orders
    todayOrders.sort((a, b) {
      // Prioritize pending orders
      if (a.status == 'Pending' && b.status != 'Pending') return -1;
      if (a.status != 'Pending' && b.status == 'Pending') return 1;

      // For pending orders, sort by ascending timestamp
      if (a.status == 'Pending' && b.status == 'Pending') {
        return a.timestamp.compareTo(b.timestamp);
      }

      // For today's completed orders, sort by ascending timestamp
      if (a.status == 'Completed' && b.status == 'Completed') {
        return a.timestamp.compareTo(b.timestamp);
      }

      return 0;
    });

    _todayOrders = todayOrders;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});

    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    final todayOrderIndex =
        _todayOrders.indexWhere((order) => order.id == orderId);

    if (orderIndex != -1) {
      _orders[orderIndex] = OrderItem(
        id: _orders[orderIndex].id,
        userName: _orders[orderIndex].userName,
        orderItems: _orders[orderIndex].orderItems,
        totalPrice: _orders[orderIndex].totalPrice,
        status: newStatus,
        timestamp: _orders[orderIndex].timestamp,
      );
    }

    if (todayOrderIndex != -1) {
      _todayOrders[orderIndex] = OrderItem(
        id: _todayOrders[orderIndex].id,
        userName: _todayOrders[orderIndex].userName,
        orderItems: _todayOrders[orderIndex].orderItems,
        totalPrice: _todayOrders[orderIndex].totalPrice,
        status: newStatus,
        timestamp: _todayOrders[orderIndex].timestamp,
      );
    }

    notifyListeners();
  }
}
