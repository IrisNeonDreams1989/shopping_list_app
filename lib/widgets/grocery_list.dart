import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _error = '';
  var _isLoading = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'shoppinglistsapp-7e589-default-rtdb.asia-southeast1.firebasedatabase.app',
      '/shopping-list.json',
    );
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      // Xử lý lỗi nếu xảy ra
      setState(() {
        _error = 'Failed to fetch data. Please try again later.';
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> _loadedItem = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      _loadedItem.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = _loadedItem;
      _isLoading = false;
    });
  }

  void _addItem(BuildContext context) async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    /*Sau khi lưu dữ liệu thành công (trong _saveItem), 
    Navigator.of(context).pop() sẽ trả về đối tượng GroceryItem cho hàm _addItem.
    Hàm _addItem sẽ nhận item mới và sử dụng setState để thêm item vào mảng _groceryItems, 
    từ đó cập nhật giao diện với danh sách item mới.*/
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
      'hoppinglistsapp-7e589-default-rtdb.asia-southeast1.firebasedatabase.app',
      '/shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(child: Text('No items yet!'));
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 50,
              height: 50,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text('${_groceryItems[index].quantity}'),
          ),
        ),
      );
    }
    if (_error.isNotEmpty) {
      content = Center(
        child: Text(_error),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addItem(context),
          ),
        ],
      ),
      body: content,
    );
  }
}
