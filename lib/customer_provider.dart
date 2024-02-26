import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Customer {
  final String name;
  final String? email;
  final String? primaryAddress;
  final String? secondaryAddress;
  final String? notes;
  final String? phone;
  final String? custType;
  final String? parentCustomer;
  final String? imagePath;
  final double totalDue;
  final String? lastSalesDate;
  final String? lastInvoiceNo;
  final String? lastSoldProduct;
  final double totalSalesValue;
  final double totalSalesReturnValue;
  final double totalAmountBack;
  final double totalCollection;
  final String? lastTransactionDate;
  final String? clientCompanyName;

  Customer({
    required this.name,
    this.email,
    this.primaryAddress,
    this.secondaryAddress,
    this.notes,
    this.phone,
    this.custType,
    this.parentCustomer,
    this.imagePath,
    required this.totalDue,
    required this.lastSalesDate,
    required this.lastInvoiceNo,
    required this.lastSoldProduct,
    required this.totalSalesValue,
    required this.totalSalesReturnValue,
    required this.totalAmountBack,
    required this.totalCollection,
    required this.lastTransactionDate,
    this.clientCompanyName,
  });
}

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  int _currentPage = 1;
  int _pageSize = 20;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Function to fetch customers based on the current page
  Future<void> fetchCustomers(String token,
      {bool nextPage = false, bool previousPage = false}) async {
    // Check if the fetch operation is already in progress
    try {
      if (_isLoading) return;

      // If nextPage is true, increment the current page
      if (nextPage) {
        _currentPage++;
      }
      // If previousPage is true and current page is greater than 1, decrement the current page
      else if (previousPage && _currentPage > 1) {
        _currentPage--;
      }

      // Set isLoading to true to indicate that fetch operation is in progress
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse(
          'https://www.pqstec.com/InvoiceApps/Values/GetCustomerList?searchquery&pageNo=$_currentPage&pageSize=$_pageSize&SortyBy=Balance',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final customerList = responseData['CustomerList'];

        if (customerList.isNotEmpty) {
          // If nextPage is true, clear previous data before adding new data
          if (nextPage || previousPage) _customers.clear();

          for (var customerData in customerList) {
            _customers.add(Customer(
              name: customerData['Name'],
              email: customerData['Email'],
              primaryAddress: customerData['PrimaryAddress'],
              secondaryAddress: customerData['SecoundaryAddress'],
              notes: customerData['Notes'],
              phone: customerData['Phone'],
              custType: customerData['CustType'],
              parentCustomer: customerData['ParentCustomer'],
              imagePath: customerData['ImagePath'],
              totalDue: (customerData['TotalDue'] ?? 0.0).toDouble(),
              lastSalesDate: customerData['LastSalesDate'],
              lastInvoiceNo: customerData['LastInvoiceNo'],
              lastSoldProduct: customerData['LastSoldProduct'],
              totalSalesValue:
                  (customerData['TotalSalesValue'] ?? 0.0).toDouble(),
              totalSalesReturnValue:
                  (customerData['TotalSalesReturnValue'] ?? 0.0).toDouble(),
              totalAmountBack:
                  (customerData['TotalAmountBack'] ?? 0.0).toDouble(),
              totalCollection:
                  (customerData['TotalCollection'] ?? 0.0).toDouble(),
              lastTransactionDate: customerData['LastTransactionDate'],
              clientCompanyName: customerData['ClinetCompanyName'],
            ));
          }
          notifyListeners();
        }
      } else {
        throw Exception('Failed to fetch customers');
      }

      // Set isLoading to false after fetch operation is completed
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      throw Exception('Error fetching data: $error');
    }
  }
}
