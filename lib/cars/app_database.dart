// REQUIRED imports
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'car_entity.dart';
import 'car_dao.dart';

part 'app_database.g.dart';

@Database(
  version: 1,
  entities: [CarEntity],
)
abstract class AppDatabase extends FloorDatabase {
  CarDao get carDao;
}
