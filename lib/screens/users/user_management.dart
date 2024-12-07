import 'package:canteen_app/providers/users_provider.dart';
import 'package:canteen_app/utils/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadUsers();
  }

  Future<void> _checkAuth() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
        return;
      }
    }

    try {
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user!.id)
          .single();

      if (userData['role'] != 'staff') {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<UserProvider>(context, listen: false).fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userProvider.users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: userProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = userProvider.users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(user['name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'No Email'),
                            Text('Role: ${user['role'] ?? 'Unknown'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showEditDialog(context, user, userProvider),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _removeUser(context, user['id'], userProvider),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _removeUser(BuildContext context, String userId, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);
                await userProvider.removeUser(userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete user: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, Map<String, dynamic> user, UserProvider userProvider) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false, // Email should not be editable
              ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['user', 'staff']
                    .map((role) => DropdownMenuItem<String>(
                          value: role,
                          child: Text(role.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                final updatedData = {
                  'name': nameController.text,
                  'role': selectedRole,
                };

                await userProvider.updateUser(user['id'], updatedData);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
