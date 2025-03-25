import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'models/product.dart';
import 'models/sale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SaleAdapter());
  Hive.registerAdapter(ProductAdapter());
  
  await Hive.openBox<Product>('products');
  await Hive.openBox<Product>('cart');
  await Hive.openBox<Sale>('sales');
  runApp(POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: const Color.fromARGB(221, 0, 0, 0)),
          bodyMedium: TextStyle(color: const Color.fromARGB(221, 0, 0, 0)),
        ),
        iconTheme: IconThemeData(color: const Color.fromARGB(255, 2, 22, 32)),
      ),
      home: HomeScreen(),
    );
  }
}
