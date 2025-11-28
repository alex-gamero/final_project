// lib/purchase_offers/purchase_offer_entity.dart
import 'package:floor/floor.dart';

/// Entity representing a Purchase Offer.
///
/// Fields:
/// - [id] : primary key (auto-generated)
/// - [customerId] : id of the customer (string to allow flexible ids)
/// - [itemId] : id of the car or boat being offered on
/// - [price] : offered price (stored as double)
/// - [offerDate] : offer date as millisecondsSinceEpoch
/// - [isAccepted] : whether the offer is accepted
/// - [details] : free text details
/// - [createdAt] : when the record was created (millisecondsSinceEpoch)
@entity
class PurchaseOffer {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String customerId;
  final String itemId;
  final double price;
  final int offerDate;
  final bool isAccepted;
  final String details;
  final int createdAt;

  PurchaseOffer({
    this.id,
    required this.customerId,
    required this.itemId,
    required this.price,
    required this.offerDate,
    required this.isAccepted,
    required this.details,
    required this.createdAt,
  });

  /// Helper to create a copy with modified fields.
  PurchaseOffer copyWith({
    int? id,
    String? customerId,
    String? itemId,
    double? price,
    int? offerDate,
    bool? isAccepted,
    String? details,
    int? createdAt,
  }) {
    return PurchaseOffer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      offerDate: offerDate ?? this.offerDate,
      isAccepted: isAccepted ?? this.isAccepted,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

