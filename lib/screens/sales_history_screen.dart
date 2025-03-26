import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late Box<Sale> salesBox;
  DateTimeRange? _selectedRange;
  String _filterType = 'Daily';

  @override
  void initState() {
    super.initState();
    salesBox = Hive.box<Sale>('sales');
  }

  List<Sale> _filteredSales() {
    final salesList = salesBox.values.toList();
    if (_selectedRange == null) return salesList;
    return salesList.where((sale) {
      return sale.date.isAfter(_selectedRange!.start.subtract(Duration(days: 1))) &&
             sale.date.isBefore(_selectedRange!.end.add(Duration(days: 1)));
    }).toList();
  }

  void _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  Future<void> _exportSalesData() async {
    final salesList = _filteredSales();
    List<List<dynamic>> rows = [
      ["Date", "Total Amount", "Amount Paid", "Change"]
    ];

    for (var sale in salesList) {
      List<dynamic> row = [];
      row.add(DateFormat.yMMMd().format(sale.date));
      row.add(sale.totalAmount);
      row.add(sale.amountPaid);
      row.add(sale.change);
      rows.add(row);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/sales_history.csv";
    final file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sales data exported to $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesList = _filteredSales();
    salesList.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportSalesData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterOptions(),
          _buildSalesChart(salesList),
          Expanded(
            child: salesList.isEmpty
                ? Center(child: Text('No sales recorded.', style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    itemCount: salesList.length,
                    itemBuilder: (context, index) {
                      final sale = salesList[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ExpansionTile(
                          title: Text('Sale on ${DateFormat.yMMMd().format(sale.date)}', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Total: \$${sale.totalAmount.toStringAsFixed(2)}'),
                          children: [
                            ListTile(
                              title: Text('Paid: \$${sale.amountPaid.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
                              subtitle: Text('Change: \$${sale.change.toStringAsFixed(2)}', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: _filterType,
            items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                _filterType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<Sale> sales) {
    Map<String, double> salesData = {};
    DateFormat format;

    switch (_filterType) {
      case 'Weekly':
        format = DateFormat("yyyy-ww"); // Weekly grouping
        break;
      case 'Monthly':
        format = DateFormat("yyyy-MM"); // Monthly grouping
        break;
      case 'Yearly':
        format = DateFormat("yyyy"); // Yearly grouping
        break;
      default:
        format = DateFormat("yyyy-MM-dd"); // Daily grouping
        break;
    }

    for (var sale in sales) {
      String date = format.format(sale.date);
      salesData.update(date, (value) => value + sale.totalAmount, ifAbsent: () => sale.totalAmount);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 220,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      return Text(salesData.keys.toList()[value.toInt()], style: TextStyle(fontSize: 12));
                    }),
                  ),
                ),
                barGroups: salesData.entries.map((entry) {
                  return BarChartGroupData(
                    x: salesData.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(toY: entry.value, color: Colors.blue, width: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}