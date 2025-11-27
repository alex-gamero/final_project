import 'package:floor/floor.dart';
import 'customer_item.dart';

@dao
abstract class CustomerDao {
  @Query('SELECT * FROM CustomerItem')
  Future<List<CustomerItem>> findAllCustomers();

  @insert
  Future<void> insertCustomer(CustomerItem customer);

  @delete
  Future<void> deleteCustomer(CustomerItem customer);
}
