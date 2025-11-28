// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cars_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  CarDao? _carDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CarEntity` (`id` INTEGER NOT NULL, `make` TEXT NOT NULL, `model` TEXT NOT NULL, `year` INTEGER NOT NULL, `price` INTEGER NOT NULL, `kilometres` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  CarDao get carDao {
    return _carDaoInstance ??= _$CarDao(database, changeListener);
  }
}

class _$CarDao extends CarDao {
  _$CarDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _carEntityInsertionAdapter = InsertionAdapter(
            database,
            'CarEntity',
            (CarEntity item) => <String, Object?>{
                  'id': item.id,
                  'make': item.make,
                  'model': item.model,
                  'year': item.year,
                  'price': item.price,
                  'kilometres': item.kilometres
                }),
        _carEntityUpdateAdapter = UpdateAdapter(
            database,
            'CarEntity',
            ['id'],
            (CarEntity item) => <String, Object?>{
                  'id': item.id,
                  'make': item.make,
                  'model': item.model,
                  'year': item.year,
                  'price': item.price,
                  'kilometres': item.kilometres
                }),
        _carEntityDeletionAdapter = DeletionAdapter(
            database,
            'CarEntity',
            ['id'],
            (CarEntity item) => <String, Object?>{
                  'id': item.id,
                  'make': item.make,
                  'model': item.model,
                  'year': item.year,
                  'price': item.price,
                  'kilometres': item.kilometres
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CarEntity> _carEntityInsertionAdapter;

  final UpdateAdapter<CarEntity> _carEntityUpdateAdapter;

  final DeletionAdapter<CarEntity> _carEntityDeletionAdapter;

  @override
  Future<List<CarEntity>> getAllCars() async {
    return _queryAdapter.queryList('SELECT * FROM CarEntity ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => CarEntity(
            id: row['id'] as int,
            make: row['make'] as String,
            model: row['model'] as String,
            year: row['year'] as int,
            price: row['price'] as int,
            kilometres: row['kilometres'] as int));
  }

  @override
  Future<void> insertCar(CarEntity car) async {
    await _carEntityInsertionAdapter.insert(car, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateCar(CarEntity car) async {
    await _carEntityUpdateAdapter.update(car, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteCar(CarEntity car) async {
    await _carEntityDeletionAdapter.delete(car);
  }
}
