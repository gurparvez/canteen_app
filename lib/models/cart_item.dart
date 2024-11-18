class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }
}
