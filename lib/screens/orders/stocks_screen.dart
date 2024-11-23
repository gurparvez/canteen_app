import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:canteen_app/models/menu_item.dart';
import 'package:canteen_app/providers/items_provider.dart';

class StocksScreen extends StatefulWidget {
  @override
  _StocksScreenState createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ItemsProvider>(context, listen: false).fetchItems();
    } catch (error) {
      debugPrint('Error fetching stock data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not fetch stock. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = Provider.of<ItemsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Loading indicator
          : itemsProvider.items.isEmpty
              ? const Center(child: Text('No items available.'))
              : ListView.builder(
                  itemCount: itemsProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = itemsProvider.items[index];
                    return ListTile(
                      leading: Image.network(
                        item.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item.name),
                      subtitle:
                          Text('Stock: ${item.stock}\nPrice: ₹${item.price}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showEditItemDialog(context, item),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteItem(context, item.id),
                          ),
                        ],
                      ),
                      onTap: () => _showUpdateStockDialog(context, item),
                    );
                  },
                ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final imageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(nameController, 'Name'),
              _buildTextField(descriptionController, 'Description'),
              _buildTextField(priceController, 'Price', isNumeric: true),
              _buildTextField(stockController, 'Stock', isNumeric: true),
              _buildTextField(imageController, 'Image URL'),
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
              final item = MenuItem(
                id: '',
                name: nameController.text,
                description: descriptionController.text,
                price: int.parse(priceController.text),
                stock: int.parse(stockController.text),
                image: imageController.text,
              );
              await Provider.of<ItemsProvider>(context, listen: false)
                  .addItem(item);
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit an item
  Future<void> _showEditItemDialog(BuildContext context, MenuItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    final imageController = TextEditingController(text: item.image);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(nameController, 'Name'),
              _buildTextField(descriptionController, 'Description'),
              _buildTextField(priceController, 'Price', isNumeric: true),
              _buildTextField(stockController, 'Stock', isNumeric: true),
              _buildTextField(imageController, 'Image URL'),
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
              final updatedItem = MenuItem(
                id: item.id,
                name: nameController.text,
                description: descriptionController.text,
                price: int.parse(priceController.text),
                stock: int.parse(stockController.text),
                image: imageController.text,
              );
              await Provider.of<ItemsProvider>(context, listen: false)
                  .updateItem(updatedItem);
              Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Show dialog to update stock
  Future<void> _showUpdateStockDialog(
      BuildContext context, MenuItem item) async {
    final stockController = TextEditingController(text: item.stock.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Stock'),
        content: _buildTextField(stockController, 'Stock', isNumeric: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newStock = int.parse(stockController.text);
              await Provider.of<ItemsProvider>(context, listen: false)
                  .updateStock(item.id, newStock);
              Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete an item
  Future<void> _deleteItem(BuildContext context, String id) async {
    await Provider.of<ItemsProvider>(context, listen: false).deleteItem(id);
  }

  // Helper to build text fields
  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }
}
