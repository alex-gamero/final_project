import 'package:floor/floor.dart';
import 'car_entity.dart';

@dao
abstract class CarDao {
  @Query('SELECT * FROM CarEntity ORDER BY id DESC')
  Future<List<CarEntity>> getAllCars();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCar(CarEntity car);

  @update
  Future<void> updateCar(CarEntity car);

  @delete
  Future<void> deleteCar(CarEntity car);
}
