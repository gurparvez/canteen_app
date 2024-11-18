import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCartData();
  }

  Future<void> _fetchCartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<CartProvider>(context, listen: false)
          .fetchCartFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cart items: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? const Center(child: Text("Your cart is empty"))
              : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text("₹${item.price} x ${item.quantity}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await cart.removeFromCart(item.id);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to remove item: $e')),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: cart.items.isEmpty
            ? null
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total: ₹${cart.totalPrice}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              await cart.clearCart();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cart emptied successfully"),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to empty cart: $e'),
                                ),
                              );
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                    child: const Text("Empty Cart"),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              await cart.placeOrder();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Order placed successfully"),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to empty cart: $e'),
                                ),
                              );
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text("Place Order"),
                  ),
                ],
              ),
      ),
    );
  }
}
