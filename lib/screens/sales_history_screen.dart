import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late Box<Sale> salesBox;
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    salesBox = Hive.box<Sale>('sales');
  }

  List<Sale> _getFilteredSales() {
    final now = DateTime.now();
    return salesBox.values.where((sale) {
      final saleDate = sale.date;
      if (filter == 'Daily') {
        return DateFormat('yyyy-MM-dd').format(saleDate) == DateFormat('yyyy-MM-dd').format(now);
      } else if (filter == 'Weekly') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return saleDate.isAfter(startOfWeek);
      } else if (filter == 'Monthly') {
        return saleDate.month == now.month && saleDate.year == now.year;
      } else if (filter == 'Yearly') {
        return saleDate.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales History'),
        actions: [
          DropdownButton<String>(
            value: filter,
            onChanged: (newValue) {
              setState(() {
                filter = newValue!;
              });
            },
            items: ['All', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: salesBox.listenable(),
        builder: (context, Box<Sale> box, _) {
          if (box.isEmpty) {
            return Center(child: Text('No sales recorded.'));
          }

          final salesList = _getFilteredSales();
          salesList.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: salesList.length,
            itemBuilder: (context, index) {
              final sale = salesList[index];
              return Card(
                child: ListTile(
                  title: Text('Sale on ${DateFormat('yyyy-MM-dd').format(sale.date)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: \$${sale.totalAmount.toStringAsFixed(2)}'),
                      Text('Paid: \$${sale.amountPaid.toStringAsFixed(2)}'),
                      Text('Change: \$${sale.change.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}