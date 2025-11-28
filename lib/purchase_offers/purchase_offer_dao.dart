//Dao updated
import 'package:floor/floor.dart';
import 'purchase_offer_entity.dart';

@dao
abstract class PurchaseOfferDao {
  @Query('SELECT * FROM PurchaseOffer ORDER BY createdAt DESC')
  Future<List<PurchaseOffer>> getAllOffers();

  @insert
  Future<int> insertOffer(PurchaseOffer offer);

  @Query('DELETE FROM PurchaseOffer WHERE id = :id')
  Future<void> deleteOffer(int id);
}