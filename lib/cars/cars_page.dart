import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  int? _selectedIndex;

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

  // ------------------------------
  // ADD / UPDATE / DELETE
  // ------------------------------
  void _showAddCarDialog({CarEntity? existingCar}) async {
    if (existingCar != null) {
      // Editing
      _make.text = existingCar.make;
      _model.text = existingCar.model;
      _year.text = existingCar.year.toString();
      _price.text = existingCar.price.toString();
      _km.text = existingCar.kilometres.toString();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
          Text(existingCar == null ? 'Add Car' : 'Edit Car'),
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

                // Copy previous car button
                if (existingCar == null)
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
                _clearFields();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            if (existingCar != null)
              TextButton(
                onPressed: () async {
                  await _db.carDao.deleteCar(existingCar);
                  await _loadCars();
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange),
              onPressed: () async {
                if (_make.text.trim().isEmpty ||
                    _model.text.trim().isEmpty) return;

                final car = CarEntity(
                  id: existingCar?.id ??
                      DateTime.now().millisecondsSinceEpoch,
                  make: _make.text.trim(),
                  model: _model.text.trim(),
                  year: int.tryParse(_year.text) ?? 0,
                  price: int.tryParse(_price.text) ?? 0,
                  kilometres: int.tryParse(_km.text) ?? 0,
                );

                if (existingCar == null) {
                  await _db.carDao.insertCar(car);
                  await _savePreviousCar(car);
                } else {
                  await _db.carDao.updateCar(car);
                }

                await _loadCars();
                _clearFields();
                Navigator.pop(context);
              },
              child: Text(existingCar == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePreviousCar(CarEntity car) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('prev_make', car.make);
    prefs.setString('prev_model', car.model);
    prefs.setInt('prev_year', car.year);
    prefs.setInt('prev_price', car.price);
    prefs.setInt('prev_km', car.kilometres);
  }

  Future<void> _loadPreviousCarData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _make.text = prefs.getString('prev_make') ?? '';
      _model.text = prefs.getString('prev_model') ?? '';
      _year.text = (prefs.getInt('prev_year') ?? 0).toString();
      _price.text = (prefs.getInt('prev_price') ?? 0).toString();
      _km.text = (prefs.getInt('prev_km') ?? 0).toString();
    });
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cars For Sale'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddCarDialog(),
        child: const Icon(Icons.add),
      ),

      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // QUICK ADD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final text = _quickAdd.text.trim();
                          if (text.isEmpty) return;

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
                            _showAddCarDialog(existingCar: car);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
