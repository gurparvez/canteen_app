import 'package:flutter/material.dart';
import 'package:canteen_app/utils/supabase_client.dart';

class UserProvider with ChangeNotifier {
  List<Map<String, dynamic>> _users = [];

  List<Map<String, dynamic>> get users => _users;

  Future<void> fetchUsers() async {
    try {
      final userSnapshot = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      _users = List<Map<String, dynamic>>.from(userSnapshot);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updatedData) async {
    try {
      await supabase.from('users').update(updatedData).eq('id', userId);

      final index = _users.indexWhere((user) => user['id'] == userId);
      if (index != -1) {
        _users[index] = {..._users[index], ...updatedData};
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> removeUser(String userId) async {
    try {
      // First delete auth user
      await supabase.auth.admin.deleteUser(userId);
      // Then delete user data
      await supabase.from('users').delete().eq('id', userId);

      _users.removeWhere((user) => user['id'] == userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing user: $e');
      rethrow;
    }
  }
}
