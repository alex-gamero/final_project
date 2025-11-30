// lib/purchase_offers/purchase_offer_dao.dart
import 'package:floor/floor.dart';
import 'purchase_offer_entity.dart';

@dao
abstract class PurchaseOfferDao {
  @Query('SELECT * FROM PurchaseOffer ORDER BY createdAt DESC')
  Future<List<PurchaseOffer>> getAllOffers();

  @Query('SELECT * FROM PurchaseOffer WHERE id = :id')
  Future<PurchaseOffer?> findOfferById(int id);

  @insert
  Future<int> insertOffer(PurchaseOffer offer);

  @update
  Future<int> updateOffer(PurchaseOffer offer);

  @delete
  Future<int> deleteOffer(PurchaseOffer offer);
}
