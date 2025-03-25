import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  _ProductManagementScreenState createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _box = Hive.box<Product>('products');
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  void _addProduct() {
    final name = _nameController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;

    if (name.isNotEmpty) {
      final product = Product(name: name, price: price, stock: stock);
      _box.add(product);
      _clearFields();
      setState(() {}); // Refresh UI
    }
  }

  void _deleteProduct(int index) {
    _box.deleteAt(index);
    setState(() {});
  }

  void _clearFields() {
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Products')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _stockController,
              decoration: InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            onPressed: _addProduct,
            child: Text('Add Product'),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box<Product> box, _) {
                if (box.isEmpty) return Center(child: Text('No products added.'));
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final product = box.getAt(index);
                    return ListTile(
                      title: Text(product!.name),
                      subtitle: Text('\$${product.price} - Stock: ${product.stock}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
