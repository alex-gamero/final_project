import 'package:floor/floor.dart';

//updated
@entity
class PurchaseOffer {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String title;
  final String details;
  final int createdAt;

  PurchaseOffer({
    this.id,
    required this.title,
    required this.details,
    required this.createdAt,
  });
}
