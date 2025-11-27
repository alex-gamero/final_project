import 'package:flutter/material.dart';
import 'package:final_project/customer/customer_item.dart';
import 'package:final_project/customer/customer_dao.dart';
import 'package:final_project/customer/app_database.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  late CustomerDao _dao;
  List<CustomerItem> customers = [];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    final database =
    await $FloorAppDatabase.databaseBuilder('customer.db').build();

    _dao = database.customerDao;
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final list = await _dao.findAllCustomers();
    setState(() {
      customers = list;
    });
  }

  Future<void> _addCustomer() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")));
      return;
    }

    final newCustomer = CustomerItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
    );

    await _dao.insertCustomer(newCustomer);
    _loadCustomers();

    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Customer added!")));
  }

  Future<void> _deleteCustomer(CustomerItem customer) async {
    await _dao.deleteCustomer(customer);
    _loadCustomers();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Customer deleted")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
      ),
      body: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Name"),
          ),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: "Phone"),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          ElevatedButton(
            onPressed: _addCustomer,
            child: const Text("Add"),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final c = customers[index];
                    return ListTile(
                      title: Text(c.name),
                      subtitle: Text("${c.phone} | ${c.email}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCustomer(c),
                      ),
                    );
                  }))
        ],
      ),
    );
  }
}
