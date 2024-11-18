import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final String userName;
  final List<Map<String, dynamic>> orderItems;
  final double totalPrice;
  final String status;
  final DateTime timestamp;

  OrderItem({
    required this.id,
    required this.userName,
    required this.orderItems,
    required this.totalPrice,
    required this.status,
    required this.timestamp,
  });

  factory OrderItem.fromMap(String id, Map<String, dynamic> data) {
    return OrderItem(
      id: id,
      userName: data['userName'] ?? 'Unknown',
      orderItems: List<Map<String, dynamic>>.from(data['orderItems']),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'Pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}