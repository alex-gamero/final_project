// lib/purchase_offers/purchase_offer_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

import 'purchase_offer_database.dart';
import 'purchase_offer_entity.dart';

/// Purchase Offer UI page that supports Add, Update, Delete and Copy Previous.
/// Uses Floor DB via PurchaseOfferDatabase and EncryptedSharedPreferences
/// to persist the previous offer for the Copy Previous feature.
class PurchaseOfferPage extends StatefulWidget {
  const PurchaseOfferPage({super.key});

  @override
  State<PurchaseOfferPage> createState() => _PurchaseOfferPageState();
}

class _PurchaseOfferPageState extends State<PurchaseOfferPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _customerController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _isAccepted = false;

  // Database
  late PurchaseOfferDatabase _database;
  List<PurchaseOffer> _offers = [];

  // Edit state
  PurchaseOffer? _editingOffer;

  // Encrypted prefs for copy-previous
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  static const _prevKey = 'purchase_offer_prev';

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _itemController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    _database = await $FloorPurchaseOfferDatabase
        .databaseBuilder('purchase_offers_floor.db')
        .build();
    await _loadOffers();
    await _loadDraft(); // load any saved draft from previous run (optional)
  }

  Future<void> _loadOffers() async {
    final list = await _database.offerDao.getAllOffers();
    setState(() {
      _offers = list;
    });
  }

  // Optional: we store a lightweight draft (not required by spec but useful)
  Future<void> _loadDraft() async {
    final jsonStr = await _prefs.getString('purchase_offer_draft');
    if (jsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(jsonStr);
        _customerController.text = map['customerId'] ?? '';
        _itemController.text = map['itemId'] ?? '';
        _priceController.text = (map['price'] ?? '').toString();
        if (map['offerDate'] != null) {
          final d = DateTime.fromMillisecondsSinceEpoch(map['offerDate']);
          _dateController.text = DateFormat.yMd().format(d);
        }
        _detailsController.text = map['details'] ?? '';
        _isAccepted = map['isAccepted'] ?? false;
      } catch (_) {
        // ignore malformed
      }
    }
  }

  Future<void> _saveDraft() async {
    final draft = {
      'customerId': _customerController.text,
      'itemId': _itemController.text,
      'price': _priceController.text,
      'offerDate': _parseDateToMillis(_dateController.text),
      'details': _detailsController.text,
      'isAccepted': _isAccepted,
    };
    await _prefs.setString('purchase_offer_draft', jsonEncode(draft));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved securely')));
  }

  int? _parseDateToMillis(String dateText) {
    try {
      final d = DateFormat.yMd().parseLoose(dateText);
      return d.millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }

  /// Clears form to default values (used for new offers).
  void _clearForm() {
    _customerController.clear();
    _itemController.clear();
    _priceController.clear();
    _dateController.clear();
    _detailsController.clear();
    _isAccepted = false;
    _editingOffer = null;
  }

  /// Populates the form with data from [offer] for editing.
  void _populateFormForEdit(PurchaseOffer offer) {
    _editingOffer = offer;
    _customerController.text = offer.customerId;
    _itemController.text = offer.itemId;
    _priceController.text = offer.price.toString();
    _dateController.text = DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(offer.offerDate));
    _detailsController.text = offer.details;
    _isAccepted = offer.isAccepted;
    setState(() {});
  }

  /// Saves the previous offer into EncryptedSharedPreferences so the user may copy later.
  Future<void> _savePreviousOffer(PurchaseOffer offer) async {
    final map = {
      'customerId': offer.customerId,
      'itemId': offer.itemId,
      'price': offer.price,
      'offerDate': offer.offerDate,
      'details': offer.details,
      'isAccepted': offer.isAccepted,
    };
    await _prefs.setString(_prevKey, jsonEncode(map));
  }

  /// Loads previous offer from EncryptedSharedPreferences and populates form.
  Future<void> _copyPreviousOffer() async {
    final jsonStr = await _prefs.getString(_prevKey);
    if (jsonStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No previous offer saved')));
      return;
    }
    try {
      final map = jsonDecode(jsonStr);
      _customerController.text = map['customerId'] ?? '';
      _itemController.text = map['itemId'] ?? '';
      _priceController.text = (map['price'] ?? '').toString();
      if (map['offerDate'] != null) {
        _dateController.text = DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(map['offerDate']));
      }
      _detailsController.text = map['details'] ?? '';
      _isAccepted = map['isAccepted'] ?? false;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Previous offer copied')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading previous offer: $e')));
    }
  }

  /// Validate common fields; returns true when valid.
  bool _validateFields() {
    final price = double.tryParse(_priceController.text);
    final dateMillis = _parseDateToMillis(_dateController.text);

    if (_customerController.text.trim().isEmpty) {
      _showError('Please enter Customer ID');
      return false;
    }
    if (_itemController.text.trim().isEmpty) {
      _showError('Please enter Car/Boat ID');
      return false;
    }
    if (price == null) {
      _showError('Please enter a valid price');
      return false;
    }
    if (dateMillis == null) {
      _showError('Please enter a valid date (use the picker)');
      return false;
    }
    if (_detailsController.text.trim().isEmpty) {
      _showError('Please enter details');
      return false;
    }
    return true;
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  /// Adds a new offer to the DB and UI.
  Future<void> _handleSave() async {
    if (!_validateFields()) return;

    final price = double.parse(_priceController.text);
    final dateMillis = _parseDateToMillis(_dateController.text)!;

    final offer = PurchaseOffer(
      customerId: _customerController.text.trim(),
      itemId: _itemController.text.trim(),
      price: price,
      offerDate: dateMillis,
      isAccepted: _isAccepted,
      details: _detailsController.text.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final id = await _database.offerDao.insertOffer(offer);
      final saved = offer.copyWith(id: id);
      await _savePreviousOffer(saved);
      await _loadOffers();
      _clearForm();
      _showSuccess('Offer added');
    } catch (e) {
      _showError('Error saving offer: $e');
    }
  }

  /// Updates an existing offer (editing mode).
  Future<void> _handleUpdate() async {
    if (_editingOffer == null) return;
    if (!_validateFields()) return;

    final price = double.parse(_priceController.text);
    final dateMillis = _parseDateToMillis(_dateController.text)!;

    final updated = _editingOffer!.copyWith(
      customerId: _customerController.text.trim(),
      itemId: _itemController.text.trim(),
      price: price,
      offerDate: dateMillis,
      isAccepted: _isAccepted,
      details: _detailsController.text.trim(),
    );

    try {
      await _database.offerDao.updateOffer(updated);
      await _savePreviousOffer(updated);
      await _loadOffers();
      _clearForm();
      _showSuccess('Offer updated');
    } catch (e) {
      _showError('Error updating offer: $e');
    }
  }

  /// Deletes the currently editing offer (asks confirmation).
  Future<void> _handleDelete() async {
    if (_editingOffer == null) return;
    final toDelete = _editingOffer!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete offer from ${toDelete.customerId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _database.offerDao.deleteOffer(toDelete);
        await _loadOffers();
        _clearForm();
        _showSuccess('Offer deleted');
      } catch (e) {
        _showError('Error deleting offer: $e');
      }
    }
  }

  /// Show a date picker and fill date field.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      _dateController.text = DateFormat.yMd().format(picked);
      setState(() {});
    }
  }

  void _enterAddMode() {
    _clearForm();
    setState(() {});
  }

  void _enterEditMode(PurchaseOffer offer) {
    _populateFormForEdit(offer);
    // scroll to form or focus if desired
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Offers'),
        actions: [
          IconButton(onPressed: _showInstructionsDialog, icon: const Icon(Icons.help_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Form (used for both add and edit)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _customerController,
                          decoration: const InputDecoration(labelText: 'Customer ID', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _itemController,
                          decoration: const InputDecoration(labelText: 'Car/Boat ID', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Offer Date', border: OutlineInputBorder()),
                          onTap: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _detailsController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Details', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const Text('Accepted'),
                          Switch(
                            value: _isAccepted,
                            onChanged: (v) => setState(() => _isAccepted = v),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _copyPreviousOffer,
                            child: const Text('Copy Previous'),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_editingOffer == null) ...[
                        ElevatedButton.icon(onPressed: _handleSave, icon: const Icon(Icons.save), label: const Text('Save Offer')),
                      ] else ...[
                        ElevatedButton.icon(onPressed: _handleUpdate, icon: const Icon(Icons.save), label: const Text('Update Offer')),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(onPressed: _handleDelete, icon: const Icon(Icons.delete), label: const Text('Delete Offer'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _enterAddMode, child: const Text('Cancel Edit')),
                      ],
                      const SizedBox(width: 12),
                      OutlinedButton(onPressed: _saveDraft, child: const Text('Save Draft')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text('Offers (${_offers.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: isWide ? Row(
                children: [
                  Expanded(flex: 3, child: _buildList()),
                  const VerticalDivider(),
                  Expanded(flex: 4, child: _buildDetailsArea()),
                ],
              ) : _buildList(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enterAddMode,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
    if (_offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.list_alt, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No offers yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return ListTile(
            leading: const Icon(Icons.local_offer),
            title: Text('${offer.customerId} → ${offer.itemId}'),
            subtitle: Text('Price: \$${offer.price.toStringAsFixed(2)} • ${DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(offer.offerDate))}'),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _enterEditMode(offer)),
            onTap: () {
              final width = MediaQuery.of(context).size.width;
              if (width > 700) {
                _populateFormForEdit(offer);
              } else {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Offer: ${offer.customerId}')),
                  body: Padding(padding: const EdgeInsets.all(12), child: OfferDetailView(offer: offer)),
                )));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailsArea() {
    if (_editingOffer == null) {
      return const Center(child: Text('Select an offer to edit or tap + to add a new offer'));
    }
    return OfferDetailView(offer: _editingOffer!);
  }

  void _showInstructionsDialog() {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('How to use'),
        content: const SingleChildScrollView(
          child: Text('Use the form to create offers. Tap an offer to edit it. You can also copy the previously created offer.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      );
    });
  }
}

/// Small detail view widget used in tablet mode and the separate detail page.
class OfferDetailView extends StatelessWidget {
  final PurchaseOffer offer;
  const OfferDetailView({required this.offer, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${offer.customerId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Item: ${offer.itemId}'),
            const SizedBox(height: 8),
            Text('Price: \$${offer.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Offer Date: ${DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(offer.offerDate))}'),
            const SizedBox(height: 8),
            Text('Accepted: ${offer.isAccepted ? "Yes" : "No"}'),
            const SizedBox(height: 12),
            const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: Text(offer.details))),
          ],
        ),
      ),
    );
  }
}
