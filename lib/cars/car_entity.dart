import 'package:floor/floor.dart';

@entity
class CarEntity {
  @primaryKey
  final int id;

  final String make;
  final String model;
  final int year;
  final int price;
  final int kilometres;

  CarEntity({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.kilometres,
  });
}
