import 'package:canteen_app/models/cart_item.dart';
import 'package:canteen_app/utils/supabase_client.dart';
import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> fetchCartFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final cartItems = await supabase
          .from('cart_items')
          .select('*, menu_items(*)')
          .eq('user_id', user.id);

      _items = cartItems.map((item) => CartItem(
            id: item['menu_items']['id'],
            name: item['menu_items']['name'],
            price: (item['menu_items']['price'] as num).toDouble(),
            quantity: item['quantity'],
          )).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching cart items: $e");
      rethrow;
    }
  }

  Future<void> addToCart(CartItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Check menu item stock
      final menuItem = await supabase
          .from('menu_items')
          .select()
          .eq('id', item.id)
          .single();

      final currentStock = menuItem['stock'] as int;
      if (currentStock < item.quantity) {
        throw Exception('Not enough stock available');
      }

      // Check if item already exists in cart
      final existingCartItem = await supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .eq('menu_item_id', item.id)
          .maybeSingle();

      if (existingCartItem == null) {
        // Add new item to cart
        await supabase.from('cart_items').insert({
          'user_id': user.id,
          'menu_item_id': item.id,
          'quantity': item.quantity,
        });

        _items.add(item);
      } else {
        // Update existing item quantity
        final newQuantity = (existingCartItem['quantity'] as int) + item.quantity;

        if (currentStock < newQuantity) {
          throw Exception('Not enough stock available for the updated quantity');
        }

        await supabase
            .from('cart_items')
            .update({'quantity': newQuantity})
            .eq('user_id', user.id)
            .eq('menu_item_id', item.id);

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

      // Update stock
      await supabase
          .from('menu_items')
          .update({'stock': currentStock - item.quantity})
          .eq('id', item.id);

      notifyListeners();
    } catch (e) {
      debugPrint("Error adding to cart: $e");
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id)
          .eq('menu_item_id', itemId);

      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing from cart: $e");
      rethrow;
    }
  }

  Future<void> clearCart() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);

      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing cart: $e");
      rethrow;
    }
  }

  Future<void> placeOrder() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Get user data
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      // Create order
      await supabase.from('orders').insert({
        'user_id': user.id,
        'user_name': userData['name'] ?? 'Unknown',
        'order_items': _items.map((item) => item.toMap()).toList(),
        'total_price': totalPrice,
        'status': 'pending',
      });

      // Clear cart after successful order
      await clearCart();
    } catch (e) {
      debugPrint("Error placing order: $e");
      rethrow;
    }
  }
}
