import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'purchase_offer_dao.dart';
import 'purchase_offer_entity.dart';

part 'purchase_offer_database.g.dart';

@Database(version: 1, entities: [PurchaseOffer])
abstract class PurchaseOfferDatabase extends FloorDatabase {
  PurchaseOfferDao get offerDao;
}
