//updated
/// purchase_offer_page.dart
///
/// Purchase Offer screen for the Vehicle Sales Management project.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path; // Add alias to avoid conflict
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Model class for a purchase offer.
class PurchaseOffer {
  int? id;
  String title;
  String details;
  DateTime createdAt;

  PurchaseOffer({this.id, required this.title, required this.details, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'details': details,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static PurchaseOffer fromMap(Map<String, dynamic> m) {
    return PurchaseOffer(
      id: m['id'] as int?,
      title: m['title'] as String,
      details: m['details'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    );
  }
}

/// Helper for SQLite database operations.
class DBHelper {
  static const _dbName = 'purchase_offers.db';
  static const _dbVersion = 1;
  static const _table = 'offers';

  DBHelper._();
  static final DBHelper instance = DBHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, _dbName); // Use aliased path
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          details TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
        ''');
      },
    );
    return _db!;
  }

  Future<int> insertOffer(PurchaseOffer offer) async {
    final db = await database;
    return await db.insert(_table, offer.toMap());
  }

  Future<List<PurchaseOffer>> getOffers() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'createdAt DESC');
    return rows.map((r) => PurchaseOffer.fromMap(r)).toList();
  }

  Future<int> deleteOffer(int id) async {
    final db = await database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

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

  static const _draftKey = 'purchase_offer_draft';

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _loadDraft();
  }

  Future<void> _loadOffers() async {
    final offers = await DBHelper.instance.getOffers();
    setState(() {
      _offers = offers;
    });
  }

  Future<void> _loadDraft() async {
    final draft = await _storage.read(key: _draftKey);
    if (draft != null && draft.isNotEmpty) {
      final parts = draft.split('\n|DETAILS|\n');
      _titleController.text = parts[0];
      if (parts.length > 1) _detailsController.text = parts[1];
    }
  }

  Future<void> _saveDraft() async {
    final draft = '${_titleController.text}\n|DETAILS|\n${_detailsController.text}';
    await _storage.write(key: _draftKey, value: draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n(Localizations.localeOf(context)).draftSaved))
      );
    }
  }

  Future<void> _addOffer() async {
    if (!_formKey.currentState!.validate()) return;
    final offer = PurchaseOffer(
        title: _titleController.text.trim(),
        details: _detailsController.text.trim()
    );
    final id = await DBHelper.instance.insertOffer(offer);
    offer.id = id;
    setState(() {
      _offers.insert(0, offer);
      _titleController.clear();
      _detailsController.clear();
    });
    await _storage.delete(key: _draftKey);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer saved'))
      );
    }
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
              await DBHelper.instance.deleteOffer(offer.id!);
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
                    decoration: const InputDecoration(labelText: 'Offer Title'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(labelText: 'Details'),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter details' : null,
                  ),
                  const SizedBox(height: 8),
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
                        label: const Text('Save Draft (secure)'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('This is a Snackbar example'))
                          );
                        },
                        child: const Text('Test Snackbar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
            child: Text('Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _offers.isEmpty
                ? const Center(child: Text('No offers yet'))
                : ListView.separated(
              itemCount: _offers.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final offer = _offers[index];
                return ListTile(
                  title: Text(offer.title),
                  subtitle: Text(
                      offer.details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever),
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
      return const Center(child: Text('Select an offer to view details'));
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
            Text('Created: ${offer.createdAt}'),
            const SizedBox(height: 12),
            Expanded(
                child: SingleChildScrollView(child: Text(offer.details))
            ),
          ],
        ),
      ),
    );
  }
}