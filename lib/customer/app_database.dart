import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'customer_item.dart';
import 'customer_dao.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [CustomerItem])
abstract class AppDatabase extends FloorDatabase {
  CustomerDao get customerDao;
}
