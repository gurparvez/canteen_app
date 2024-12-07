class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String image;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.image,
  });

  // Convert a Firestore document to a MenuItem object
  factory MenuItem.fromMap(String id, Map<String, dynamic> data) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      stock: data['stock'] ?? 0,
      image: data['image'] ?? '',
    );
  }

  // Convert a MenuItem object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
    };
  }
}
