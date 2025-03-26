import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Box<Product> cartBox;
  double _amountPaid = 0.0;

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<Product>('cart');
  }

  void _updateQuantity(Product product, int newQuantity) {
    if (newQuantity > 0) {
      product.stock = newQuantity;
      product.save();
    } else {
      cartBox.delete(product.key);
    }
    setState(() {});
  }

  double _calculateTotal() {
    return cartBox.values.fold(0, (sum, item) => sum + (item.price * item.stock));
  }

  void _processCheckout() {
    double total = _calculateTotal();
    double change = _amountPaid - total;
    if (_amountPaid >= total) {
      cartBox.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Transaction Successful'),
          content: Text('Change: \$${change.toStringAsFixed(2)}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
      setState(() {});
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Insufficient Payment'),
          content: Text('Please enter enough amount to cover the total.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: cartBox.listenable(),
              builder: (context, Box<Product> box, _) {
                if (box.isEmpty) return Center(child: Text('Cart is empty', style: TextStyle(fontSize: 16)));
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final product = box.getAt(index);
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(product!.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Quantity: ${product.stock} | Price: \$${product.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _updateQuantity(product, product.stock - 1),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => _updateQuantity(product, product.stock + 1),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('Total: \$${_calculateTotal().toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Amount Paid',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _amountPaid = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _processCheckout,
                  child: Text('Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

void saveSale(List<Product> list, double total, double amountPaid, double change) {
}
