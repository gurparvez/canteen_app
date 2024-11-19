import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserOrder {
  final String id;
  final List<Map<String, dynamic>> orderItems;
  final double totalPrice;
  final String status;
  final DateTime timestamp;

  UserOrder({
    required this.id,
    required this.orderItems,
    required this.totalPrice,
    required this.status,
    required this.timestamp,
  });

  factory UserOrder.fromMap(String id, Map<String, dynamic> data) {
    return UserOrder(
      id: id,
      orderItems: List<Map<String, dynamic>>.from(data['orderItems']),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'Pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class UserOrdersProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<UserOrder> _orders = [];

  List<UserOrder> get orders => _orders;

  Future<void> fetchUserOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    _orders = snapshot.docs.map((doc) => UserOrder.fromMap(doc.id, doc.data())).toList();
    notifyListeners();
  }
}
