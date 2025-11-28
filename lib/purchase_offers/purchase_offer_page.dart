/// purchase_offer_page.dart
///
/// Purchase Offer screen using Floor ORM (consistent with Cars page)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import your Floor database and entities
import 'purchase_offer_database.dart';
import 'purchase_offer_entity.dart';

/// Simple localized strings used by this screen.
class L10n {
  final Locale locale;
  L10n(this.locale);

  static const supported = [Locale('en', 'US'), Locale('en', 'GB')];

  String get title => 'Purchase Offer';
  String get instruction => locale.countryCode == 'GB'
      ? 'Enter an offer title and details. Use the Save button to add to the list.'
      : 'Enter an offer title and details. Use the Save button to add to the list.';

  String get draftSaved => 'Draft saved securely.';
}

/// PurchaseOfferPage - the main UI for the "Offers" part of the project.
class PurchaseOfferPage extends StatefulWidget {
  const PurchaseOfferPage({super.key});

  @override
  State<PurchaseOfferPage> createState() => _PurchaseOfferPageState();
}

class _PurchaseOfferPageState extends State<PurchaseOfferPage> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  List<PurchaseOffer> _offers = [];
  PurchaseOffer? _selected;

  late PurchaseOfferDatabase _database;
  static const _draftKey = 'purchase_offer_draft';

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await $FloorPurchaseOfferDatabase
        .databaseBuilder('purchase_offer_database.db')
        .build();
    _loadOffers();
    _loadDraft();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _database.offerDao.getAllOffers();
      print('Loaded ${offers.length} offers from DB');
      setState(() {
        _offers = offers;
      });
    } catch (e) {
      print('Error loading offers: $e');
      setState(() {
        _offers = [];
      });
    }
  }

  Future<void> _loadDraft() async {
    try {
      final draft = await _storage.read(key: _draftKey);
      if (draft != null && draft.isNotEmpty) {
        final parts = draft.split('\n|DETAILS|\n');
        _titleController.text = parts[0];
        if (parts.length > 1) _detailsController.text = parts[1];
      }
    } catch (e) {
      print('Error loading draft: $e');
    }
  }

  Future<void> _saveDraft() async {
    try {
      final draft = '${_titleController.text}\n|DETAILS|\n${_detailsController.text}';
      await _storage.write(key: _draftKey, value: draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n(Localizations.localeOf(context)).draftSaved))
        );
      }
    } catch (e) {
      print('Error saving draft: $e');
    }
  }

  Future<void> _addOffer() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    print('✅ Form validated successfully');
    print('📝 Title: ${_titleController.text}');
    print('📝 Details: ${_detailsController.text}');

    final offer = PurchaseOffer(
      title: _titleController.text.trim(),
      details: _detailsController.text.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      print('🔄 Starting database insert...');
      final id = await _database.offerDao.insertOffer(offer);
      print('✅ Offer inserted with ID: $id');

      // Create the saved offer with the actual ID
      final savedOffer = PurchaseOffer(
        id: id,
        title: offer.title,
        details: offer.details,
        createdAt: offer.createdAt,
      );

      print('🔄 Updating UI with new offer...');
      setState(() {
        _offers.insert(0, savedOffer);
        _titleController.clear();
        _detailsController.clear();
      });

      // Clear draft after successful save
      await _storage.delete(key: _draftKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Offer saved successfully!')),
        );
      }

      print('✅ Offer added to list. Total offers: ${_offers.length}');

    } catch (e) {
      print('❌ Error saving offer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error saving offer: $e')),
        );
      }
    }
  }

  // Test method to add offer without database
  void _testAddOffer() {
    final testOffer = PurchaseOffer(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Test Offer ${DateTime.now().second}',
      details: 'This is a test offer added directly to the list',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _offers.insert(0, testOffer);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Test offer added directly to list!')),
    );
  }

  void _showInstructions() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('How to use'),
        content: Text(L10n(Localizations.localeOf(context)).instruction),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')
          )
        ],
      ),
    );
  }

  void _confirmDelete(PurchaseOffer offer) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: Text('Delete "${offer.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () async {
              try {
                await _database.offerDao.deleteOffer(offer.id!);
                if (mounted) {
                  setState(() {
                    _offers.removeWhere((o) => o.id == offer.id);
                    if (_selected?.id == offer.id) _selected = null;
                  });
                }
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer deleted'))
                  );
                }
              } catch (e) {
                print('Error deleting offer: $e');
              }
            },
            child: const Text('Delete'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n(Localizations.localeOf(context));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.title),
        actions: [
          IconButton(
              onPressed: _showInstructions,
              icon: const Icon(Icons.info_outline)
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Offer Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addOffer,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Offer'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _saveDraft,
                        icon: const Icon(Icons.lock),
                        label: const Text('Save Draft'),
                      ),
                      const SizedBox(width: 8),
                      // Test button
                      OutlinedButton(
                        onPressed: _testAddOffer,
                        child: const Text('Test Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Offers List (${_offers.length} items)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Row(
                      children: [
                        Flexible(flex: 3, child: _buildList()),
                        const VerticalDivider(width: 1),
                        Flexible(flex: 4, child: _buildDetailsArea()),
                      ],
                    );
                  } else {
                    return _buildList();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Saved Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _offers.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No offers yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Add your first offer using the form above',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
                : ListView.separated(
              itemCount: _offers.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final offer = _offers[index];
                return ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: Text(offer.title),
                  subtitle: Text(
                      offer.details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _confirmDelete(offer),
                  ),
                  onTap: () {
                    final width = MediaQuery.of(context).size.width;
                    if (width > 700) {
                      setState(() {
                        _selected = offer;
                      });
                    } else {
                      Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (BuildContext context) => OfferDetailPage(offer: offer)
                          )
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsArea() {
    if (_selected == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select an offer to view details', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return OfferDetailView(offer: _selected!);
  }
}

/// Full-screen details page used on narrow devices.
class OfferDetailPage extends StatelessWidget {
  final PurchaseOffer offer;
  const OfferDetailPage({required this.offer, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(offer.title)),
      body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: OfferDetailView(offer: offer)
      ),
    );
  }
}

/// Reusable details view used both side-by-side and full-screen.
class OfferDetailView extends StatelessWidget {
  final PurchaseOffer offer;
  const OfferDetailView({required this.offer, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                offer.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text('Created: ${DateTime.fromMillisecondsSinceEpoch(offer.createdAt)}'),
            const SizedBox(height: 12),
            const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    offer.details,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }
}