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
  DateTime? selectedDate; // Add a variable to store the selected date

  @override
  void initState() {
    super.initState();
    salesBox = Hive.box<Sale>('sales');
  }

  List<Sale> _getFilteredSales() {
    final now = DateTime.now();
    return salesBox.values.where((sale) {
      final saleDate = sale.date;
      if (selectedDate != null) {
        // Filter by the selected date
        return DateFormat('yyyy-MM-dd').format(saleDate) ==
            DateFormat('yyyy-MM-dd').format(selectedDate!);
      } else if (filter == 'Daily') {
        return DateFormat('yyyy-MM-dd').format(saleDate) ==
            DateFormat('yyyy-MM-dd').format(now);
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        filter = 'All'; // Reset other filters when a date is selected
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: filter,
              onChanged: (newValue) {
                setState(() {
                  filter = newValue!;
                  selectedDate = null;
                });
              },
              items: ['All', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Colors.blueGrey[50],
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
          valueListenable: salesBox.listenable(),
          builder: (context, Box<Sale> box, _) {
            if (box.isEmpty) {
              return const Center(
                child: Text(
                  'No sales recorded.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final salesList = _getFilteredSales();
            salesList.sort((a, b) => b.date.compareTo(a.date));

            return ListView.builder(
              itemCount: salesList.length,
              itemBuilder: (context, index) {
                final sale = salesList[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      'Sale on ${DateFormat('yyyy-MM-dd').format(sale.date)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${sale.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                        Text(
                          'Paid: \$${sale.amountPaid.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                        Text(
                          'Change: \$${sale.change.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}