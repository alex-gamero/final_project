import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'app_database.dart';
import 'car_entity.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  late AppDatabase _db;
  List<CarEntity> _cars = [];

  CarEntity? _selectedCar;

  final EncryptedSharedPreferences _encryptedPrefs = EncryptedSharedPreferences();

  // Controllers
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _km = TextEditingController();
  final _quickAdd = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDb();
    _loadRecentSearch();
  }

  Future<void> _initDb() async {
    _db = await $FloorAppDatabase
        .databaseBuilder('cars_database.db')
        .build();

    _loadCars();
  }

  Future<void> _loadCars() async {
    final list = await _db.carDao.getAllCars();
    setState(() => _cars = list);
  }

  // ========================================================
  // SNACKBAR - Show success message
  // ========================================================
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
  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: "Dismiss",
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
  void _showInstructionsDialog() {
    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("How to Use This App"),
          content: const SingleChildScrollView(
            child: Text(
              "Instructions:\n\n"
                  "1. Use the 'Add' button to create new car listings\n"
                  "2. Tap on any car in the list to view/edit details\n"
                  "3. Use 'Update' to save changes or 'Delete' to remove\n"
                  "4. Quick Add field lets you quickly add cars with just the make\n"
                  "5. Use 'Copy Previous Car' to duplicate the last added car's data",
            ),
          ),
          actions: [
            OutlinedButton(
              child: const Text("Got it!"),
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
  void _showStatisticsDialog() {
    final totalCars = _cars.length;
    final averagePrice = totalCars > 0
        ? _cars.map((car) => car.price).reduce((a, b) => a + b) / totalCars
        : 0;

    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cars Statistics"),
          content: Text(
            "Current Statistics:\n\n"
                "Total Cars: $totalCars\n"
                "Average Price: \$${averagePrice.toStringAsFixed(2)}\n"
                "Selected Car: ${_selectedCar?.make ?? 'None'}\n\n"
                "This shows the current state of your car inventory.",
          ),
          actions: [
            OutlinedButton(
              child: const Text("Close"),
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
        title: const Text('Cars For Sale'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
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
                _showSuccessSnackbar("Selection cleared");
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
                    _showErrorSnackbar("Please enter a car make first!");
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
                  _showSuccessSnackbar("Car '$text' added successfully!");
                },
                child: const Text("Add item"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _quickAdd,
                  decoration: const InputDecoration(
                    labelText: 'Quick Add (Make)',
                    border: OutlineInputBorder(),
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
                  child: const Text("Show Statistics"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showSuccessSnackbar("List refreshed! Total cars: ${_cars.length}");
                  },
                  child: const Text("Refresh List"),
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
                  Text('Price: \$${car.price} | KM: ${car.kilometres}'),
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
  Widget _buildDetailsPage() {
    if (_selectedCar == null) {
      return const Center(
        child: Text(
          "Select a car to view details",
          style: TextStyle(fontSize: 18, color: Colors.grey),
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
              "Car Details",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),

            _input(_make, "Make"),
            const SizedBox(height: 12),

            _input(_model, "Model"),
            const SizedBox(height: 12),

            _input(_year, "Year", number: true),
            const SizedBox(height: 12),

            _input(_price, "Price", number: true),
            const SizedBox(height: 12),

            _input(_km, "Kilometres", number: true),
            const SizedBox(height: 20),

            // Additional buttons for notifications
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showInstructionsDialog,
                    child: const Text("Help"),
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
                      _showSuccessSnackbar("Car updated successfully!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text("Update"),
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
                            title: const Text("Confirm Delete"),
                            content: Text(
                                "Are you sure you want to delete ${_selectedCar!.make} ${_selectedCar!.model}? This action cannot be undone."),
                            actions: [
                              OutlinedButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showSuccessSnackbar("Delete cancelled");
                                },
                              ),
                              OutlinedButton(
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _db.carDao.deleteCar(_selectedCar!);
                                  final carName = "${_selectedCar!.make} ${_selectedCar!.model}";
                                  _selectedCar = null;
                                  await _loadCars();
                                  setState(() {});
                                  _showSuccessSnackbar("Car '$carName' deleted successfully!");
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
                    child: const Text("Delete"),
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
  void _openAddDialog() {
    _clearFields();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Car"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(_make, 'Make'),
              const SizedBox(height: 8),
              _input(_model, 'Model'),
              const SizedBox(height: 8),
              _input(_year, 'Year', number: true),
              const SizedBox(height: 8),
              _input(_price, 'Price', number: true),
              const SizedBox(height: 8),
              _input(_km, 'Kilometres', number: true),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _loadPreviousCarData,
                child: const Text("Copy Previous Car"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_make.text.isEmpty || _model.text.isEmpty) {
                _showErrorSnackbar("Please fill in all required fields!");
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
              _showSuccessSnackbar("Car '${car.make} ${car.model}' added successfully!");
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // ========================================================
  // PREVIOUS CAR
  // ========================================================
  Future<void> _savePreviousCar(CarEntity car) async {
    await _encryptedPrefs.setString('prev_make', car.make);
    await _encryptedPrefs.setString('prev_model', car.model);
    await _encryptedPrefs.setString('prev_year', car.year.toString());
    await _encryptedPrefs.setString('prev_price', car.price.toString());
    await _encryptedPrefs.setString('prev_km', car.kilometres.toString());
  }

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
    _showSuccessSnackbar("Previous car data loaded!");
  }

  // Method for saving recent searches in the Quick Add field
  Future<void> _saveRecentSearch(String searchText) async {
    if (searchText.trim().isNotEmpty) {
      await _encryptedPrefs.setString('recent_search', searchText.trim());
    }
  }

  // Method for loading recent search
  Future<void> _loadRecentSearch() async {
    final recentSearch = await _encryptedPrefs.getString('recent_search');
    if (recentSearch.isNotEmpty) {
      _quickAdd.text = recentSearch;
    }
  }

  // ========================================================
  // HELPERS
  // ========================================================
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

  void _clearFields() {
    _make.clear();
    _model.clear();
    _year.clear();
    _price.clear();
    _km.clear();
  }
}