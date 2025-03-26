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

  void _addToCart(Product product) {
    final existingProductKey = cartBox.keys.firstWhere(
      (key) {
        final item = cartBox.get(key);
        return item != null && item.name == product.name;
      },
      orElse: () => null,
    );

    if (existingProductKey != null) {
      final existingProduct = cartBox.get(existingProductKey);
      final updatedProduct = Product(
        name: existingProduct!.name,
        price: existingProduct.price,
        stock: existingProduct.stock,
        quantity: existingProduct.quantity + 1, // Increase quantity by 1
      );

      cartBox.put(existingProductKey, updatedProduct);
    } else {
      final newProduct = Product(
        name: product.name,
        price: product.price,
        stock: product.stock,
        quantity: 1, // Set quantity to 1
      );
      cartBox.add(newProduct);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
      ),
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
                if (box.isEmpty) return Center(child: Text('No products available', style: TextStyle(fontSize: 16)));
                return ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    int quantity = productQuantities[product.key] ?? 1; // Default to 1

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${product.price} - Stock: ${product.stock}'),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      if (quantity > 1) {
                                        productQuantities[product.key] = quantity - 1;
                                      }
                                    });
                                  },
                                ),
                                Text(quantity.toString(), style: TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () {
                                    setState(() {
                                      productQuantities[product.key] = quantity + 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () => _addToCart(product),
                              child: Text('Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
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