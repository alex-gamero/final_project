import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'car_entity.dart';
import 'car_dao.dart';

part 'app_database.g.dart';

/// The main database class for the Vehicle Sales Management application.
/// 
/// This abstract class serves as the central database configuration using
/// the Floor ORM (Object-Relational Mapping) library for Flutter.
/// It defines the database schema, version, and provides access to DAOs.
/// 
/// The class is extended by the generated `_$AppDatabase` class which
/// provides the concrete implementation of the database operations.
@Database(
  version: 1,
  entities: [CarEntity],
)
abstract class AppDatabase extends FloorDatabase {
  /// Provides access to the Car Data Access Object (DAO).
  /// 
  /// This getter returns an instance of [CarDao] that can be used to perform
  /// CRUD operations on the CarEntity table, including:
  /// - Retrieving all cars
  /// - Inserting new cars
  /// - Updating existing cars
  /// - Deleting cars
  /// 
  /// Returns:
  /// An instance of [CarDao] for car-related database operations.
  CarDao get carDao;
}