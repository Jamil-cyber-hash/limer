import 'package:hive/hive.dart';
import 'product.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale extends HiveObject {
  @HiveField(0)
  List<Product> products;

  @HiveField(1)
  double totalAmount;

  @HiveField(2)
  double amountPaid;

  @HiveField(3)
  double change;

  @HiveField(4)
  DateTime dateTime;

  Sale({
    required this.products,
    required this.totalAmount,
    required this.amountPaid,
    required this.change,
    required this.dateTime,
  });
}
