import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'app_database.dart';
import 'car_entity.dart';
import '../localization/app_localizations.dart';
import '../main.dart';

/// A page for managing cars inventory with CRUD operations and internationalization support.
///
/// This widget provides a responsive interface for adding, viewing, updating, and deleting
/// car listings with support for both phone and tablet layouts.
class CarsPage extends StatefulWidget {
  /// Creates a [CarsPage] widget.
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

/// The state class for [CarsPage] that manages the car inventory and user interface.
///
/// This class handles database operations, form management, and responsive layout
/// for the cars management functionality.
class _CarsPageState extends State<CarsPage> {
  /// The database instance for car data persistence.
  late AppDatabase _db;

  /// List of cars currently loaded from the database.
  List<CarEntity> _cars = [];

  /// The currently selected car for viewing or editing details.
  CarEntity? _selectedCar;

  /// Encrypted shared preferences instance for secure data storage.
  final EncryptedSharedPreferences _encryptedPrefs = EncryptedSharedPreferences();

  // Controllers
  /// Text editing controller for the car make input field.
  final _make = TextEditingController();

  /// Text editing controller for the car model input field.
  final _model = TextEditingController();

  /// Text editing controller for the car year input field.
  final _year = TextEditingController();

  /// Text editing controller for the car price input field.
  final _price = TextEditingController();

  /// Text editing controller for the car kilometres input field.
  final _km = TextEditingController();

  /// Text editing controller for the quick add input field.
  final _quickAdd = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDb();
    _loadRecentSearch();
  }

  /// Initializes the database connection and loads initial car data.
  Future<void> _initDb() async {
    _db = await $FloorAppDatabase
        .databaseBuilder('cars_database.db')
        .build();

    _loadCars();
  }

  /// Loads all cars from the database and updates the UI.
  Future<void> _loadCars() async {
    final list = await _db.carDao.getAllCars();
    setState(() => _cars = list);
  }

  // ========================================================
  // SNACKBAR - Show success message
  // ========================================================

  /// Displays a success snackbar with a green background.
  ///
  /// Parameters:
  /// - [message]: The success message to display
  void _showSuccessSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      action: SnackBarAction(
        label: "OK",
        textColor: Colors.white,
        onPressed: () {
          // Action when pressed
        },
      ),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ========================================================
  // SNACKBAR - Show error message
  // ========================================================

  /// Displays an error snackbar with a red background.
  ///
  /// Parameters:
  /// - [message]: The error message to display
  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.translate('close'),
        textColor: Colors.white,
        onPressed: () {
          // Action when pressed
        },
      ),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ========================================================
  // ALERT DIALOG - Show instructions
  // ========================================================

  /// Shows an alert dialog with application usage instructions.
  void _showInstructionsDialog() {
    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('instructions_title')),
          content: SingleChildScrollView(
            child: Text(AppLocalizations.of(context)!.translate('instructions_content')),
          ),
          actions: [
            OutlinedButton(
              child: Text(AppLocalizations.of(context)!.translate('got_it')),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ========================================================
  // ALERT DIALOG - Show statistics
  // ========================================================

  /// Shows an alert dialog with car inventory statistics.
  void _showStatisticsDialog() {
    final totalCars = _cars.length;
    final averagePrice = totalCars > 0
        ? _cars.map((car) => car.price).reduce((a, b) => a + b) / totalCars
        : 0;

    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('statistics_title')),
          content: Text(
            AppLocalizations.of(context)!.translate(
                'statistics_content',
                {
                  'totalCars': totalCars.toString(),
                  'averagePrice': averagePrice.toStringAsFixed(2),
                  'selectedCar': _selectedCar?.make ?? 'None'
                }
            ),
          ),
          actions: [
            OutlinedButton(
              child: Text(AppLocalizations.of(context)!.translate('close')),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ========================================================
  // RESPONSIVE LAYOUT
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('app_title')),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Language button
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageDialog,
          ),
          // Instructions button
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructionsDialog,
          ),
          // Statistics button
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatisticsDialog,
          ),
          if (_selectedCar != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _selectedCar = null);
                _showSuccessSnackbar(AppLocalizations.of(context)!.translate('selection_cleared'));
              },
            )
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Main add button
          FloatingActionButton(
            backgroundColor: Colors.orange,
            onPressed: () => _openAddDialog(),
            child: const Icon(Icons.add),
          ),
        ],
      ),

      body: reactiveLayout(),
    );
  }

  // ========================================================
  // MASTER-DETAIL selector
  // ========================================================

  /// Creates a responsive layout that adapts to phone and tablet screen sizes.
  ///
  /// Returns:
  /// - For tablets: A row with list view and details side by side
  /// - For phones: Either the list view or details view based on selection
  Widget reactiveLayout() {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isTablet = (width > height) && (width > 720);

    if (isTablet) {
      // TABLET VERSION
      return Row(
        children: [
          Expanded(flex: 2, child: _buildListView()),
          Expanded(flex: 3, child: _buildDetailsPage()),
        ],
      );
    } else {
      // PHONE VERSION
      if (_selectedCar == null) {
        return _buildListView();
      } else {
        return _buildDetailsPage();
      }
    }
  }

  // ========================================================
  // LEFT PANEL: LIST VIEW
  // ========================================================

  /// Builds the list view panel showing all cars with quick add functionality.
  Widget _buildListView() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final text = _quickAdd.text.trim();
                  if (text.isEmpty) {
                    _showErrorSnackbar(AppLocalizations.of(context)!.translate('enter_car_make'));
                    return;
                  }

                  await _saveRecentSearch(text);

                  final car = CarEntity(
                    id: DateTime.now().millisecondsSinceEpoch,
                    make: text,
                    model: "Unknown",
                    year: 0,
                    price: 0,
                    kilometres: 0,
                  );

                  await _db.carDao.insertCar(car);
                  _quickAdd.clear();
                  await _loadCars();
                  _showSuccessSnackbar(
                      AppLocalizations.of(context)!.translate('car_added', {'make': text})
                  );
                },
                child: Text(AppLocalizations.of(context)!.translate('add_item')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _quickAdd,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.translate('quick_add_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Button to show alert dialog
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _showStatisticsDialog,
                  child: Text(AppLocalizations.of(context)!.translate('show_statistics')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showSuccessSnackbar(
                        AppLocalizations.of(context)!.translate(
                            'list_refreshed',
                            {'count': _cars.length.toString()}
                        )
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.translate('refresh_list')),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            itemCount: _cars.length,
            itemBuilder: (context, index) {
              final car = _cars[index];

              return Card(
                child: ListTile(
                  title: Text('${car.year} ${car.make} ${car.model}'),
                  subtitle:
                  Text('${AppLocalizations.of(context)!.translate('price')}: \$${car.price} | '
                      '${AppLocalizations.of(context)!.translate('kilometres')}: ${car.kilometres}'),
                  onTap: () {
                    setState(() {
                      _selectedCar = car;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========================================================
  // RIGHT PANEL: DETAILS PAGE
  // ========================================================

  /// Builds the details panel for viewing and editing selected car information.
  Widget _buildDetailsPage() {
    if (_selectedCar == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.translate('select_car_message'),
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // preload into controllers
    _make.text = _selectedCar!.make;
    _model.text = _selectedCar!.model;
    _year.text = _selectedCar!.year.toString();
    _price.text = _selectedCar!.price.toString();
    _km.text = _selectedCar!.kilometres.toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.translate('car_details'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),

            _input(_make, AppLocalizations.of(context)!.translate('make')),
            const SizedBox(height: 12),

            _input(_model, AppLocalizations.of(context)!.translate('model')),
            const SizedBox(height: 12),

            _input(_year, AppLocalizations.of(context)!.translate('year'), number: true),
            const SizedBox(height: 12),

            _input(_price, AppLocalizations.of(context)!.translate('price'), number: true),
            const SizedBox(height: 12),

            _input(_km, AppLocalizations.of(context)!.translate('kilometres'), number: true),
            const SizedBox(height: 20),

            // Additional buttons for notifications
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showInstructionsDialog,
                    child: Text(AppLocalizations.of(context)!.translate('help')),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = CarEntity(
                        id: _selectedCar!.id,
                        make: _make.text,
                        model: _model.text,
                        year: int.tryParse(_year.text) ?? 0,
                        price: int.tryParse(_price.text) ?? 0,
                        kilometres: int.tryParse(_km.text) ?? 0,
                      );

                      await _db.carDao.updateCar(updated);
                      _selectedCar = updated;
                      await _loadCars();
                      setState(() {});
                      _showSuccessSnackbar(AppLocalizations.of(context)!.translate('car_updated'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('update')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show confirmation dialog before delete
                      showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.translate('confirm_delete')),
                            content: Text(
                              AppLocalizations.of(context)!.translate(
                                  'delete_confirmation_message',
                                  {
                                    'make': _selectedCar!.make,
                                    'model': _selectedCar!.model
                                  }
                              ),
                            ),
                            actions: [
                              OutlinedButton(
                                child: Text(AppLocalizations.of(context)!.translate('cancel')),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showSuccessSnackbar(AppLocalizations.of(context)!.translate('delete_cancelled'));
                                },
                              ),
                              OutlinedButton(
                                child: Text(AppLocalizations.of(context)!.translate('delete'), style: TextStyle(color: Colors.red)),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _db.carDao.deleteCar(_selectedCar!);
                                  final carName = "${_selectedCar!.make} ${_selectedCar!.model}";
                                  _selectedCar = null;
                                  await _loadCars();
                                  setState(() {});
                                  _showSuccessSnackbar(
                                      AppLocalizations.of(context)!.translate(
                                          'car_deleted',
                                          {'carName': carName}
                                      )
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('delete')),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // ========================================================
  // ADD DIALOG (PHONE ONLY, optional)
  // ========================================================

  /// Shows a dialog for adding a new car to the inventory.
  void _openAddDialog() {
    _clearFields();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('add_car')),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(_make, AppLocalizations.of(context)!.translate('make')),
              const SizedBox(height: 8),
              _input(_make, AppLocalizations.of(context)!.translate('model')),
              const SizedBox(height: 8),
              _input(_year, AppLocalizations.of(context)!.translate('year'), number: true),
              const SizedBox(height: 8),
              _input(_price, AppLocalizations.of(context)!.translate('price'), number: true),
              const SizedBox(height: 8),
              _input(_km, AppLocalizations.of(context)!.translate('kilometres'), number: true),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _loadPreviousCarData,
                child: Text(AppLocalizations.of(context)!.translate('copy_previous_car')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_make.text.isEmpty || _model.text.isEmpty) {
                _showErrorSnackbar(AppLocalizations.of(context)!.translate('fill_required_fields'));
                return;
              }

              final car = CarEntity(
                id: DateTime.now().millisecondsSinceEpoch,
                make: _make.text,
                model: _model.text,
                year: int.tryParse(_year.text) ?? 0,
                price: int.tryParse(_price.text) ?? 0,
                kilometres: int.tryParse(_km.text) ?? 0,
              );

              await _db.carDao.insertCar(car);
              await _savePreviousCar(car);
              await _loadCars();

              Navigator.pop(context);
              _showSuccessSnackbar(
                  AppLocalizations.of(context)!.translate(
                      'car_added',
                      {'make': car.make}
                  )
              );
            },
            child: Text(AppLocalizations.of(context)!.translate('add')),
          )
        ],
      ),
    );
  }

  // ========================================================
  // PREVIOUS CAR
  // ========================================================

  /// Saves the current car data to encrypted shared preferences for future use.
  ///
  /// Parameters:
  /// - [car]: The car entity to save as previous car data
  Future<void> _savePreviousCar(CarEntity car) async {
    await _encryptedPrefs.setString('prev_make', car.make);
    await _encryptedPrefs.setString('prev_model', car.model);
    await _encryptedPrefs.setString('prev_year', car.year.toString());
    await _encryptedPrefs.setString('prev_price', car.price.toString());
    await _encryptedPrefs.setString('prev_km', car.kilometres.toString());
  }

  /// Loads previously saved car data from encrypted shared preferences into the form.
  Future<void> _loadPreviousCarData() async {
    final prevMake = await _encryptedPrefs.getString('prev_make');
    final prevModel = await _encryptedPrefs.getString('prev_model');
    final prevYear = await _encryptedPrefs.getString('prev_year');
    final prevPrice = await _encryptedPrefs.getString('prev_price');
    final prevKm = await _encryptedPrefs.getString('prev_km');

    setState(() {
      _make.text = prevMake;
      _model.text = prevModel;
      _year.text = prevYear;
      _price.text = prevPrice;
      _km.text = prevKm;
    });
    _showSuccessSnackbar(AppLocalizations.of(context)!.translate('previous_data_loaded'));
  }

  // ========================================================
  // SAVE RECENT SEARCH
  // ========================================================

  /// Saves the recent search text to encrypted shared preferences.
  ///
  /// Parameters:
  /// - [searchText]: The text to save as recent search
  Future<void> _saveRecentSearch(String searchText) async {
    if (searchText.trim().isNotEmpty) {
      await _encryptedPrefs.setString('recent_search', searchText.trim());
    }
  }

  /// Loads the recent search text from encrypted shared preferences.
  Future<void> _loadRecentSearch() async {
    final recentSearch = await _encryptedPrefs.getString('recent_search');
    if (recentSearch.isNotEmpty) {
      _quickAdd.text = recentSearch;
    }
  }

  // ========================================================
  // INTERNATIONALIZATION
  // ========================================================

  /// Changes the application language to the specified locale.
  ///
  /// Parameters:
  /// - [locale]: The new locale to switch to
  void _changeLanguage(Locale locale) {
    MyApp.setLocale(context, locale);
  }

  /// Shows a dialog for selecting the application language.
  void _showLanguageDialog() {
    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('english')),
                onTap: () {
                  Navigator.pop(context);
                  _changeLanguage(const Locale('en'));
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.translate('spanish')),
                onTap: () {
                  Navigator.pop(context);
                  _changeLanguage(const Locale('es'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================================
  // HELPERS
  // ========================================================

  /// Creates a standardized text input field with consistent styling.
  ///
  /// Parameters:
  /// - [c]: The text editing controller for the input field
  /// - [label]: The label text for the input field
  /// - [number]: Whether the input should use number keyboard
  ///
  /// Returns:
  /// A styled [TextField] widget
  Widget _input(TextEditingController c, String label,
      {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Clears all text input fields in the form.
  void _clearFields() {
    _make.clear();
    _model.clear();
    _year.clear();
    _price.clear();
    _km.clear();
  }
}