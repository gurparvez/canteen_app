import 'package:flutter/material.dart';
import 'CartItem.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(CartItem item) {
    final index = _items.indexWhere((cartItem) => cartItem.id == item.id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }

    notifyListeners();
  }

  void removeFromCart(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  double get totalPrice =>
      _items.fold(0, (total, item) => total + item.price * item.quantity);
}
