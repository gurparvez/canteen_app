import 'package:canteen_app/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<CartItem> get items => _items;

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> fetchCartFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      _items = cartSnapshot.docs
          .map((doc) => CartItem.fromMap(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching cart items: $e");
    }
  }

  Future<void> addToCart(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final menuItemDocRef = _firestore.collection('menuItems').doc(item.id);
    final cartDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(item.id);

    // Fetch the menu item to check stock
    final menuItemDoc = await menuItemDocRef.get();
    if (!menuItemDoc.exists) {
      throw Exception('Menu item not found');
    }

    final menuItemData = menuItemDoc.data();
    final currentStock = menuItemData?['stock'] ?? 0;

    if (currentStock < item.quantity) {
      throw Exception('Not enough stock available');
    }

    // Check if the item already exists in the cart
    final existingDoc = await cartDocRef.get();

    if (!existingDoc.exists) {
      // If the item does not exist, add it to the cart
      await cartDocRef.set(item.toMap());

      _items.add(item);
    } else {
      // If the item exists, increment the quantity
      final currentQuantity = existingDoc.data()?['quantity'] ?? 0;
      final newQuantity = currentQuantity + item.quantity;

      if (currentStock < newQuantity) {
        throw Exception('Not enough stock available for the updated quantity');
      }

      await cartDocRef.update({'quantity': newQuantity});

      // Update local cart list
      final existingItemIndex = _items.indexWhere((i) => i.id == item.id);
      if (existingItemIndex != -1) {
        _items[existingItemIndex] = CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: newQuantity,
        );
      }
    }

    // Reduce the stock in the menuItems collection
    final updatedStock = currentStock - item.quantity;
    await menuItemDocRef.update({'stock': updatedStock});

    notifyListeners();
  }

  Future<void> removeFromCart(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(itemId)
        .delete();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) return;

    final cartCollection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final cartSnapshot = await cartCollection.get();
    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? "Unknown";

    final orderData = {
      'userId': user.uid,
      'userName': userName,
      'orderItems': _items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending', // Initial status of the order
    };

    // Add the order to the orders collection
    await _firestore.collection('orders').add(orderData);

    // Clear the cart after placing the order
    await clearCart();
  }
}
