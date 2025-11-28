import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  CarEntity? _selectedCar; // ⭐ MODO MASTER–DETAIL

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
          if (_selectedCar != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedCar = null),
            )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _openAddDialog(),
        child: const Icon(Icons.add),
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
                      await _db.carDao.deleteCar(_selectedCar!);
                      _selectedCar = null;
                      await _loadCars();
                      setState(() {});
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
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
