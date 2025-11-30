// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_offer_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $PurchaseOfferDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $PurchaseOfferDatabaseBuilderContract addMigrations(
      List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $PurchaseOfferDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<PurchaseOfferDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorPurchaseOfferDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $PurchaseOfferDatabaseBuilderContract databaseBuilder(String name) =>
      _$PurchaseOfferDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $PurchaseOfferDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$PurchaseOfferDatabaseBuilder(null);
}

class _$PurchaseOfferDatabaseBuilder
    implements $PurchaseOfferDatabaseBuilderContract {
  _$PurchaseOfferDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $PurchaseOfferDatabaseBuilderContract addMigrations(
      List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $PurchaseOfferDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<PurchaseOfferDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$PurchaseOfferDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$PurchaseOfferDatabase extends PurchaseOfferDatabase {
  _$PurchaseOfferDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  PurchaseOfferDao? _offerDaoInstance;

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
            'CREATE TABLE IF NOT EXISTS `PurchaseOffer` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `customerId` TEXT NOT NULL, `itemId` TEXT NOT NULL, `price` REAL NOT NULL, `offerDate` INTEGER NOT NULL, `isAccepted` INTEGER NOT NULL, `details` TEXT NOT NULL, `createdAt` INTEGER NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  PurchaseOfferDao get offerDao {
    return _offerDaoInstance ??= _$PurchaseOfferDao(database, changeListener);
  }
}

class _$PurchaseOfferDao extends PurchaseOfferDao {
  _$PurchaseOfferDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _purchaseOfferInsertionAdapter = InsertionAdapter(
            database,
            'PurchaseOffer',
            (PurchaseOffer item) => <String, Object?>{
                  'id': item.id,
                  'customerId': item.customerId,
                  'itemId': item.itemId,
                  'price': item.price,
                  'offerDate': item.offerDate,
                  'isAccepted': item.isAccepted ? 1 : 0,
                  'details': item.details,
                  'createdAt': item.createdAt
                }),
        _purchaseOfferUpdateAdapter = UpdateAdapter(
            database,
            'PurchaseOffer',
            ['id'],
            (PurchaseOffer item) => <String, Object?>{
                  'id': item.id,
                  'customerId': item.customerId,
                  'itemId': item.itemId,
                  'price': item.price,
                  'offerDate': item.offerDate,
                  'isAccepted': item.isAccepted ? 1 : 0,
                  'details': item.details,
                  'createdAt': item.createdAt
                }),
        _purchaseOfferDeletionAdapter = DeletionAdapter(
            database,
            'PurchaseOffer',
            ['id'],
            (PurchaseOffer item) => <String, Object?>{
                  'id': item.id,
                  'customerId': item.customerId,
                  'itemId': item.itemId,
                  'price': item.price,
                  'offerDate': item.offerDate,
                  'isAccepted': item.isAccepted ? 1 : 0,
                  'details': item.details,
                  'createdAt': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<PurchaseOffer> _purchaseOfferInsertionAdapter;

  final UpdateAdapter<PurchaseOffer> _purchaseOfferUpdateAdapter;

  final DeletionAdapter<PurchaseOffer> _purchaseOfferDeletionAdapter;

  @override
  Future<List<PurchaseOffer>> getAllOffers() async {
    return _queryAdapter.queryList(
        'SELECT * FROM PurchaseOffer ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => PurchaseOffer(
            id: row['id'] as int?,
            customerId: row['customerId'] as String,
            itemId: row['itemId'] as String,
            price: row['price'] as double,
            offerDate: row['offerDate'] as int,
            isAccepted: (row['isAccepted'] as int) != 0,
            details: row['details'] as String,
            createdAt: row['createdAt'] as int));
  }

  @override
  Future<PurchaseOffer?> findOfferById(int id) async {
    return _queryAdapter.query('SELECT * FROM PurchaseOffer WHERE id = ?1',
        mapper: (Map<String, Object?> row) => PurchaseOffer(
            id: row['id'] as int?,
            customerId: row['customerId'] as String,
            itemId: row['itemId'] as String,
            price: row['price'] as double,
            offerDate: row['offerDate'] as int,
            isAccepted: (row['isAccepted'] as int) != 0,
            details: row['details'] as String,
            createdAt: row['createdAt'] as int),
        arguments: [id]);
  }

  @override
  Future<int> insertOffer(PurchaseOffer offer) {
    return _purchaseOfferInsertionAdapter.insertAndReturnId(
        offer, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateOffer(PurchaseOffer offer) {
    return _purchaseOfferUpdateAdapter.updateAndReturnChangedRows(
        offer, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteOffer(PurchaseOffer offer) {
    return _purchaseOfferDeletionAdapter.deleteAndReturnChangedRows(offer);
  }
}
