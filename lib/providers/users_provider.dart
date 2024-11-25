import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _users = [];

  List<Map<String, dynamic>> get users => _users;

  // Fetch all users from Firestore
  Future<void> fetchUsers() async {
    final userSnapshot = await _firestore.collection('users').get();

    _users = userSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include the document ID
      return data;
    }).toList();

    notifyListeners();
  }

  // Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('users').doc(userId).update(updatedData);

    final index = _users.indexWhere((user) => user['id'] == userId);
    if (index != -1) {
      _users[index] = {..._users[index], ...updatedData};
    }

    notifyListeners();
  }

  // Remove a user
  Future<void> removeUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();

    _users.removeWhere((user) => user['id'] == userId);

    notifyListeners();
  }
}
