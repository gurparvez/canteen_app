import 'package:canteen_app/models/order_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<OrderItem> _orders = [];

  List<OrderItem> get orders => _orders;

  Future<void> fetchOrders() async {
    final snapshot = await _firestore
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .get();

    _orders = snapshot.docs
        .map((doc) => OrderItem.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex] = OrderItem(
        id: _orders[orderIndex].id,
        userName: _orders[orderIndex].userName,
        orderItems: _orders[orderIndex].orderItems,
        totalPrice: _orders[orderIndex].totalPrice,
        status: newStatus,
        timestamp: _orders[orderIndex].timestamp,
      );
      notifyListeners();
    }
  }
}
