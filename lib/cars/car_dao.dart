import 'package:floor/floor.dart';
import 'car_entity.dart';

/// Data Access Object (DAO) for car entity database operations.
///
/// This abstract class defines the contract for performing CRUD (Create, Read, Update, Delete)
/// operations on the CarEntity table in the local database using Floor ORM.
@dao
abstract class CarDao {
  /// Retrieves all car entities from the database in descending order by ID.
  ///
  /// Returns:
  /// A [Future] that completes with a list of [CarEntity] objects, ordered by
  /// ID in descending order (newest cars first).
  @Query('SELECT * FROM CarEntity ORDER BY id DESC')
  Future<List<CarEntity>> getAllCars();

  /// Inserts a new car entity into the database.
  ///
  /// Uses replace conflict strategy to update existing records if a car with
  /// the same primary key already exists.
  ///
  /// Parameters:
  /// - [car]: The car entity to insert into the database
  ///
  /// Returns:
  /// A [Future] that completes when the insertion operation is finished.
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCar(CarEntity car);

  /// Updates an existing car entity in the database.
  ///
  /// Modifies the database record for the specified car entity based on its primary key.
  ///
  /// Parameters:
  /// - [car]: The car entity with updated values to save to the database
  ///
  /// Returns:
  /// A [Future] that completes when the update operation is finished.
  @update
  Future<void> updateCar(CarEntity car);

  /// Deletes a car entity from the database.
  ///
  /// Removes the specified car entity from the database based on its primary key.
  ///
  /// Parameters:
  /// - [car]: The car entity to delete from the database
  ///
  /// Returns:
  /// A [Future] that completes when the deletion operation is finished.
  @delete
  Future<void> deleteCar(CarEntity car);
}