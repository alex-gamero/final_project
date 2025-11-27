import 'package:floor/floor.dart';

@entity
class CustomerItem {
  @primaryKey
  final int id;

  final String name;
  final String phone;
  final String email;

  CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });
}
