import 'package:floor/floor.dart';

@entity
class CustomerItem {
  @primaryKey
  final int id;

  final String firstName;
  final String lastName;
  final String phone;
  final String email;

  CustomerItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
  });
}
