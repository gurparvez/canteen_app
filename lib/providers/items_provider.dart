import 'package:canteen_app/models/menu_item.dart';
import 'package:canteen_app/utils/supabase_client.dart';
import 'package:flutter/material.dart';

class ItemsProvider with ChangeNotifier {
  List<MenuItem> _items = [];

  List<MenuItem> get items => _items;

  Future<void> fetchItems() async {
    try {
      final data = await supabase.from('menu_items').select();
      _items = data.map((item) {
        return MenuItem(
          id: item['id'],
          name: item['name'],
          description: item['description'],
          price: (item['price'] as num).toDouble(),
          stock: item['stock'],
          image: item['image'],
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching items: $e');
      rethrow;
    }
  }

  Future<void> addItem(MenuItem item) async {
    try {
      final response = await supabase
          .from('menu_items')
          .insert({
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'stock': item.stock,
            'image': item.image,
          })
          .select()
          .single();

      _items.add(MenuItem(
        id: response['id'],
        name: item.name,
        description: item.description,
        price: item.price,
        stock: item.stock,
        image: item.image,
      ));

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(MenuItem item) async {
    try {
      await supabase.from('menu_items').update({
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'stock': item.stock,
        'image': item.image,
      }).eq('id', item.id);

      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await supabase.from('menu_items').delete().eq('id', id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
      rethrow;
    }
  }

  Future<void> updateStock(String id, int newStock) async {
    try {
      await supabase
          .from('menu_items')
          .update({'stock': newStock})
          .eq('id', id);

      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = MenuItem(
          id: _items[index].id,
          name: _items[index].name,
          description: _items[index].description,
          price: _items[index].price,
          stock: newStock,
          image: _items[index].image,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }
}
