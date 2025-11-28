import 'package:flutter/material.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  final List<Car> _cars = [];
  int? _selectedIndex;

  // Controllers for FULL car creation
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();

  // CONTROLLER for PART 2 (quick add)
  final TextEditingController _quickAddController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cars For Sale'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _showAddCarDialog,
        child: const Icon(Icons.add),
      ),

      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ---------------------------
                //        PART 2
                // ---------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Add button
                      ElevatedButton(
                        onPressed: () {
                          final text = _quickAddController.text.trim();
                          if (text.isEmpty) return;

                          setState(() {
                            _cars.add(
                              Car(
                                make: text,
                                model: 'Unknown',
                                year: 0,
                                price: 0,
                                kilometres: 0,
                              ),
                            );
                            _quickAddController.clear();
                          });
                        },
                        child: const Text("Add item"),
                      ),
                      const SizedBox(width: 12),

                      // TextField
                      Expanded(
                        child: TextField(
                          controller: _quickAddController,
                          decoration: const InputDecoration(
                            labelText: 'Quick Add (Make)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;

                            setState(() {
                              _cars.add(Car(
                                make: value,
                                model: "Unknown",
                                year: 0,
                                price: 0,
                                kilometres: 0,
                              ));
                              _quickAddController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // LIST OF CARS
                Expanded(
                  child: ListView.builder(
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      final car = _cars[index];
                      final selected = _selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          if (isWide) {
                            setState(() => _selectedIndex = index);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CarDetailsPage(car: car),
                              ),
                            );
                          }
                        },
                        child: Card(
                          color: selected ? Colors.orange.shade100 : null,
                          child: ListTile(
                            title: Text('${car.year} ${car.make} ${car.model}'),
                            subtitle: Text(
                              'Price: \$${car.price} | KM: ${car.kilometres}',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right-side details (wide screens)
          if (isWide && _selectedIndex != null)
            SizedBox(
              width: 350,
              child: CarDetailsPage(car: _cars[_selectedIndex!]),
            ),
        ],
      ),
    );
  }

  // ------------------------------
  //  ADD CAR (FULL FORM)
  // ------------------------------
  void _showAddCarDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Car'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _input(_makeController, 'Make'),
                const SizedBox(height: 8),
                _input(_modelController, 'Model'),
                const SizedBox(height: 8),
                _input(_yearController, 'Year', number: true),
                const SizedBox(height: 8),
                _input(_priceController, 'Price', number: true),
                const SizedBox(height: 8),
                _input(_kmController, 'Kilometres', number: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (_makeController.text.trim().isEmpty ||
                    _modelController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  _cars.add(
                    Car(
                      make: _makeController.text,
                      model: _modelController.text,
                      year: int.tryParse(_yearController.text) ?? 0,
                      price: int.tryParse(_priceController.text) ?? 0,
                      kilometres: int.tryParse(_kmController.text) ?? 0,
                    ),
                  );
                });

                _clearFields();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Helpers
  Widget _input(TextEditingController c, String label, {bool number = false}) {
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
    _makeController.clear();
    _modelController.clear();
    _yearController.clear();
    _priceController.clear();
    _kmController.clear();
  }
}

// ----------------------------
//   CAR MODEL
// ----------------------------
class Car {
  final String make;
  final String model;
  final int year;
  final int price;
  final int kilometres;

  Car({
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.kilometres,
  });
}

// ----------------------------
//   DETAILS PAGE
// ----------------------------
class CarDetailsPage extends StatelessWidget {
  final Car car;

  const CarDetailsPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
        title: const Text('Car Details'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${car.year} ${car.make} ${car.model}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Price: \$${car.price}'),
            Text('Kilometres: ${car.kilometres}'),
          ],
        ),
      ),
    );
  }
}
