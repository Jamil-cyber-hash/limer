import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';

class SalesHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final salesBox = Hive.box<Sale>('sales');

    return Scaffold(
      appBar: AppBar(title: Text('Sales History')),
      body: ValueListenableBuilder(
        valueListenable: salesBox.listenable(),
        builder: (context, Box<Sale> box, _) {
          if (box.isEmpty) {
            return Center(child: Text('No sales recorded.'));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final sale = box.getAt(index);
              if (sale == null) return SizedBox.shrink();

              return Card(
                child: ListTile(
                  title: Text('Sale on ${sale.dateTime.toString()}'),
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
