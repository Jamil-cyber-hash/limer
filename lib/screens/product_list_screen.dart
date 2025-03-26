import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Box<Product> productBox;
  late Box<Product> cartBox;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  Map<int, int> productQuantities = {}; // Track selected quantities

  @override
  void initState() {
    super.initState();
    productBox = Hive.box<Product>('products');
    cartBox = Hive.box<Product>('cart');
    _filteredProducts = productBox.values.toList();
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = productBox.values
          .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addToCart(Product product, int quantity) {
    if (product.stock >= quantity) {
      setState(() {
        product.stock -= quantity;
        productBox.put(product.key, product);
        for (int i = 0; i < quantity; i++) {
          cartBox.add(Product(
            name: product.name,
            price: product.price,
            stock: 1, // Store individually in cart
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: productBox.listenable(),
              builder: (context, Box<Product> box, _) {
                if (box.isEmpty) return Center(child: Text('No products available'));
                return ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    int quantity = productQuantities[product.key] ?? 1; // Default to 1
                    
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$${product.price} - Stock: ${product.stock}'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: quantity.toDouble(),
                                  min: 1,
                                  max: product.stock.toDouble(),
                                  divisions: product.stock > 0 ? product.stock : 1,
                                  label: quantity.toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      productQuantities[product.key] = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _addToCart(product, quantity),
                                child: Text('Add to Cart'),
                              )
                            ],
                          )
                        ],
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