import 'package:canteen_app/models/menu_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItemsProvider with ChangeNotifier {
  List<MenuItem> _items = [];

  // Getter for items
  List<MenuItem> get items => _items;

  // Fetch items from Firestore
  Future<void> fetchItems() async {
    final data = await FirebaseFirestore.instance.collection('menuItems').get();
    _items = data.docs.map((doc) {
      return MenuItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
    notifyListeners();
  }

  // Add a new item
  Future<void> addItem(MenuItem item) async {
    final doc = await FirebaseFirestore.instance
        .collection('menuItems')
        .add(item.toMap());

    _items.add(MenuItem(
      id: doc.id,
      name: item.name,
      description: item.description,
      price: item.price,
      stock: item.stock,
      image: item.image,
    ));

    notifyListeners();
  }

  // Update an existing item
  Future<void> updateItem(MenuItem item) async {
    await FirebaseFirestore.instance
        .collection('menuItems')
        .doc(item.id)
        .update(item.toMap());
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  // Delete an item
  Future<void> deleteItem(String id) async {
    await FirebaseFirestore.instance.collection('menuItems').doc(id).delete();
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Update stock
  Future<void> updateStock(String id, int newStock) async {
    await FirebaseFirestore.instance
        .collection('menuItems')
        .doc(id)
        .update({'stock': newStock});

    final index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      final updatedItem = MenuItem(
        id: _items[index].id,
        name: _items[index].name,
        description: _items[index].description,
        price: _items[index].price,
        stock: newStock,
        image: _items[index].image,
      );
      _items[index] = updatedItem;

      notifyListeners();
    }
  }
}
