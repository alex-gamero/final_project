import 'package:floor/floor.dart';

/// Represents a car entity in the vehicle sales management system.
///
/// This class defines the structure of car data stored in the local database
/// and is used throughout the application for car inventory management.
@entity
class CarEntity {
  /// The unique identifier for the car entity.
  ///
  /// This primary key is used to uniquely identify each car record
  /// in the database and is typically generated using timestamp-based
  /// values to ensure uniqueness.
  @primaryKey
  final int id;

  /// The manufacturer or brand of the car.
  ///
  /// Examples: Toyota, Honda, Ford, Tesla
  final String make;

  /// The specific model name of the car.
  ///
  /// Examples: Corolla, Civic, Model 3, Mustang
  final String model;

  /// The manufacturing year of the car.
  ///
  /// Represents the year the car was produced (e.g., 2020, 2021, 2022)
  final int year;

  /// The selling price of the car in the local currency.
  ///
  /// Stored as an integer value, typically representing the price
  /// in the smallest currency unit (e.g., cents for USD)
  final int price;

  /// The total distance the car has been driven, in kilometres.
  ///
  /// This represents the odometer reading and is used to indicate
  /// the vehicle's usage and condition.
  final int kilometres;

  /// Creates a new [CarEntity] instance with the specified properties.
  ///
  /// Parameters:
  /// - [id]: The unique identifier for the car
  /// - [make]: The manufacturer/brand of the car
  /// - [model]: The specific model name of the car
  /// - [year]: The manufacturing year of the car
  /// - [price]: The selling price of the car
  /// - [kilometres]: The distance driven in kilometres
  CarEntity({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.kilometres,
  });
}