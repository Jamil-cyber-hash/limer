import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';

class CartScreenV2 extends StatefulWidget {
  const CartScreenV2({super.key});

  @override
  _CartScreenV2State createState() => _CartScreenV2State();
}

class _CartScreenV2State extends State<CartScreenV2> {
  late Box<Product> cartBox;
  final TextEditingController _paymentController = TextEditingController();
  double _amountPaid = 0.0;

  @override
  void initState() {
    super.initState();
    cartBox = Hive.box<Product>('cart');
  }

  void _removeFromCart(int key) {
    cartBox.delete(key);
    setState(() {});
  }

  double _calculateTotal() {
    return cartBox.values.fold(0, (sum, product) {
      return sum + product.price;
    });
  }

  void _processCheckout() {
  double total = _calculateTotal();
  double change = _amountPaid - total;

  if (_amountPaid >= total) {
    _saveSale(total); // ✅ Save the sale record before clearing cart
    cartBox.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Successful'),
        content: Text('Change: \$${change.toStringAsFixed(2)}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Payment'),
        content: Text('Enter a sufficient amount.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }
}

void _saveSale(double totalAmount) async {
  var salesBox = await Hive.openBox<Sale>('sales');
  Sale newSale = Sale(
    products: cartBox.values.toList(),
    totalAmount: totalAmount,
    amountPaid: _amountPaid,
    change: _amountPaid - totalAmount,
    date: DateTime.now(),
    amount: cartBox.length,
  );
  
  await salesBox.add(newSale);
  print("✅ Sale saved: \$${newSale.amount} on ${newSale.date}");
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: cartBox.listenable(),
              builder: (context, Box<Product> box, _) {
                if (box.isEmpty) return Center(child: Text('Cart is empty'));

                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final key = box.keys.elementAt(index);
                    final product = box.get(key);
                    if (product == null) return SizedBox.shrink();

                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeFromCart(key),
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
                  controller: _paymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount Paid', border: OutlineInputBorder()),
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
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
