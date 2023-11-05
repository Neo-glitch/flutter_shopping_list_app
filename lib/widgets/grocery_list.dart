import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/dummy_items.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

// one screen for the grocery list
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final List<GroceryItem> _groceryItems = [];

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) {
        return const NewItemScreen();
      }),
    );
    if (newItem == null) {
      // back button on previous screen was pressed
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No Items addded yet"),
    );

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemBuilder: (ctx, idx) => Dismissible(
          key: ValueKey(_groceryItems[idx].id),
          onDismissed: (direction) {
            _removeItem(_groceryItems[idx]);
          },
          child: ListTile(
            title: Text(_groceryItems[idx].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[idx].category.color,
            ),
            trailing: Text(_groceryItems[idx].quantity.toString()),
          ),
        ),
        itemCount: _groceryItems.length,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
              onPressed: _addItem,
              icon: const Icon(
                Icons.add,
              ))
        ],
      ),
      body: content,
    );
  }
}
