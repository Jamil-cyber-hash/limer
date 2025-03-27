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

  void _addToCart(Product product, int selectedQuantity) {
  final existingProductKey = cartBox.keys.firstWhere(
    (key) {
      final item = cartBox.get(key);
      return item != null && item.name == product.name;
    },
    orElse: () => null,
  );

  if (existingProductKey != null) {
    // ✅ Clone the product with updated quantity
    final existingProduct = cartBox.get(existingProductKey);
    final updatedProduct = Product(
      name: existingProduct!.name,
      price: existingProduct.price,
      stock: existingProduct.stock,
      quantity: selectedQuantity, // ✅ Use selected quantity
    );

    cartBox.put(existingProductKey, updatedProduct); // ✅ Store cloned object
  } else {
    // 🆕 Add new product if not in cart
    final newProduct = Product(
      name: product.name,
      price: product.price,
      stock: product.stock,
      quantity: selectedQuantity, // ✅ Use selected quantity
    );
    cartBox.add(newProduct);
  }

  setState(() {});
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: productBox.listenable(),
                builder: (context, Box<Product> box, _) {
                  if (box.isEmpty) {
                    return const Center(
                      child: Text(
                        'No products available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      int quantity = productQuantities[product.key] ?? 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${product.price.toStringAsFixed(2)} - Stock: ${product.stock}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                  ElevatedButton.icon(
                                    onPressed: () => _addToCart(product, quantity),
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}