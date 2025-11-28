import 'package:flutter/material.dart';

import 'customer_item.dart';
import 'customer_dao.dart';
import 'app_database.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  late CustomerDao dao;
  List<CustomerItem> customers = [];


  final TextEditingController _firstCtrl = TextEditingController();
  final TextEditingController _lastCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();


  CustomerItem? selectedItem;
  bool isEditing = false;


  final TextEditingController _detailFirstCtrl = TextEditingController();
  final TextEditingController _detailLastCtrl = TextEditingController();
  final TextEditingController _detailPhoneCtrl = TextEditingController();
  final TextEditingController _detailEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    final db = await $FloorAppDatabase.databaseBuilder('customer_database.db').build();
    dao = db.customerDao;

    final list = await dao.findAllCustomers();
    setState(() => customers = list);
  }

  Future<void> _refresh() async {
    final list = await dao.findAllCustomers();
    setState(() => customers = list);
  }

  // -------------- Input validation for all required fields ----------------

  String? _validateCustomerFields({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
  }) {
    if (firstName.trim().isEmpty) {
      return 'First name is required';
    }
    if (firstName.trim().length > 30) {
      return 'First name must have max. 30 characters';
    }

    if (lastName.trim().isEmpty) {
      return 'Last name is required';
    }
    if (lastName.trim().length > 30) {
      return 'Last name must have max. 30 characters';
    }

    final phoneReg = RegExp(r'^\d{10}$');
    if (!phoneReg.hasMatch(phone.trim())) {
      return 'Phone must have 10 digits';
    }

    final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailReg.hasMatch(email.trim())) {
      return 'Email must be like: xxx@yyy.zzz';
    }

    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // -------------- Add new customers with comprehensive details  ----------------

  Future<void> _addCustomer() async {
    final first = _firstCtrl.text;
    final last = _lastCtrl.text;
    final phone = _phoneCtrl.text;
    final email = _emailCtrl.text;

    final error = _validateCustomerFields(
      firstName: first,
      lastName: last,
      phone: phone,
      email: email,
    );

    if (error != null) {
      _showError(error);
      return;
    }

    final newCustomer = CustomerItem(
      id: DateTime.now().millisecondsSinceEpoch,
      firstName: first.trim(),
      lastName: last.trim(),
      phone: phone.trim(),
      email: email.trim(),
    );

    await dao.insertCustomer(newCustomer);
    _clearInputs();
    await _refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer added successfully')),
    );
  }

  void _clearInputs() {
    _firstCtrl.clear();
    _lastCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
  }

  // -------------- Copy previous customer data functionality ----------------

  void _copyPreviousCustomer() {
    if (selectedItem != null) {
      _firstCtrl.text = selectedItem!.firstName;
      _lastCtrl.text = selectedItem!.lastName;
      _phoneCtrl.text = selectedItem!.phone;
      _emailCtrl.text = selectedItem!.email;
    } else if (customers.isNotEmpty) {
      final last = customers.last;
      _firstCtrl.text = last.firstName;
      _lastCtrl.text = last.lastName;
      _phoneCtrl.text = last.phone;
      _emailCtrl.text = last.email;
    } else {
      _showError('There is no previous customer to copy from');
    }
  }

  // -------------- View customer detailed information  ----------------

  void _selectCustomer(CustomerItem c) {
    setState(() {
      selectedItem = c;
      isEditing = false;

      _detailFirstCtrl.text = c.firstName;
      _detailLastCtrl.text = c.lastName;
      _detailPhoneCtrl.text = c.phone;
      _detailEmailCtrl.text = c.email;
    });
  }

      // ---------- Update customer information --------
  void _startEditing() {
    setState(() {
      isEditing = true;
    });
  }

  void _cancelEditing() {
    if (selectedItem != null) {
      _detailFirstCtrl.text = selectedItem!.firstName;
      _detailLastCtrl.text = selectedItem!.lastName;
      _detailPhoneCtrl.text = selectedItem!.phone;
      _detailEmailCtrl.text = selectedItem!.email;
    }
    setState(() {
      isEditing = false;
    });
  }

  Future<void> _saveEditing() async {
    if (selectedItem == null) return;

    final first = _detailFirstCtrl.text;
    final last = _detailLastCtrl.text;
    final phone = _detailPhoneCtrl.text;
    final email = _detailEmailCtrl.text;

    final error = _validateCustomerFields(
      firstName: first,
      lastName: last,
      phone: phone,
      email: email,
    );

    if (error != null) {
      _showError(error);
      return;
    }

     final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm changes'),
        content: const Text(
            'Are your sure you want to update this costumer information?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final updated = CustomerItem(
      id: selectedItem!.id,
      firstName: first.trim(),
      lastName: last.trim(),
      phone: phone.trim(),
      email: email.trim(),
    );

    await dao.updateCustomer(updated);

    setState(() {
      selectedItem = updated;
      isEditing = false;
    });

    await _refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer updated successfully')),
    );
  }

  // ---------- Delete customer information --------
  Future<void> _deleteSelected() async {
    if (selectedItem == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete customer'),
        content: const Text('Are your sure you want to delete this costumer information?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await dao.deleteCustomer(selectedItem!);
    setState(() {
      selectedItem = null;
      isEditing = false;
    });
    await _refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer deleted successfully')),
    );
  }

  void _closeDetails() {
    setState(() {
      selectedItem = null;
      isEditing = false;
    });
  }

  // -------------- Professional UI Design ----------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = (size.width > size.height) && (size.width > 720);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        centerTitle: true,
      ),
      body: isTablet ? _tabletLayout() : _phoneLayout(),
    );
  }

  Widget _phoneLayout() {
    if (selectedItem == null) {
      return _listPage();
    } else {
      return _detailsPage();
    }
  }

  Widget _tabletLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _listPage()),
        Expanded(flex: 3, child: _detailsPage()),
      ],
    );
  }

  // -------------- Professional UI Design (List and Form)  ----------------

  Widget _listPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lastCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (xxx-xxx-xxxx)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (xxx@yyy.zzz)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),


          Row(
            children: [
              ElevatedButton(
                onPressed: _addCustomer,
                child: const Text("Add Customer"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _copyPreviousCustomer,
                child: const Text("Copy Previous"),
              ),
            ],
          ),
          const SizedBox(height: 12),


          Expanded(
            child: customers.isEmpty
                ? const Center(child: Text("No customers in the list yet."))
                : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (_, i) {
                final c = customers[i];

                return GestureDetector(
                  onTap: () => _selectCustomer(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Center(
                      child: Text(
                        "${i + 1}: ${c.firstName} ${c.lastName}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------- View customer information----------------

  Widget _detailsPage() {
    if (selectedItem == null) {
      return const Center(
        child: Text("Select a customer from the list"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Customer Details",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _detailFirstCtrl,
            readOnly: !isEditing,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailLastCtrl,
            readOnly: !isEditing,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailPhoneCtrl,
            readOnly: !isEditing,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailEmailCtrl,
            readOnly: !isEditing,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text("ID: ${selectedItem!.id}"),

          const SizedBox(height: 16),


          if (!isEditing) ...[
            Row(
              children: [
                ElevatedButton(
                  onPressed: _startEditing,
                  child: const Text("Update"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _deleteSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _closeDetails,
                  child: const Text("Close"),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveEditing,
                  child: const Text("Save"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _cancelEditing,
                  child: const Text("Close"),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
