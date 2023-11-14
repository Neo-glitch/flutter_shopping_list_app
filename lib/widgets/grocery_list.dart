import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/data/dummy_items.dart';
import 'package:shopping_list_app/models/category.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

// one screen for the grocery list
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      "shopping-list-app-edfb3-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception("Failed to fetch data. Please try again later.");
      // error
      // setState(() {
      //   _error = "Failed to fetch data. Please try again later.";
      // });
    }

    if (response.body == "null") {
      // we have no response body if if response was 200
      // this happens if we have no items in db
      return [];
    }

    // decodes json to map
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      // to get first element value in our categories map that match condition
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value["category"],
          )
          .value;

      loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category),
      );
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) {
        return const NewItemScreen();
      }),
    );

    if (newItem == null) {
      // if user returns to this screen on back press button
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final deleteIdx = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      "shopping-list-app-edfb3-default-rtdb.firebaseio.com",
      "shopping-list/${item.id}.json",
    );
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      if (context.mounted) {
        const snackBar = SnackBar(
            content: Text("Failed to delete item. Please try again later."));
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
      // error
      setState(() {
        _groceryItems.insert(deleteIdx, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            // executes this builder method as the future changes it state
            if (snapshot.connectionState == ConnectionState.waiting) {
              // equivalent to loading state since waiting for response
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              // if future was rejected due to error
              return Center(child: Text(snapshot.error.toString()));
            }

            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No Items addded yet"),
              );
            }

            return ListView.builder(
              itemBuilder: (ctx, idx) => Dismissible(
                key: ValueKey(snapshot.data![idx].id),
                onDismissed: (direction) {
                  _removeItem(snapshot.data![idx]);
                },
                child: ListTile(
                  title: Text(snapshot.data![idx].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![idx].category.color,
                  ),
                  trailing: Text(snapshot.data![idx].quantity.toString()),
                ),
              ),
              itemCount: snapshot.data!.length,
            );
          }),
    );
  }
}
