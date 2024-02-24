import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Map<String, dynamic>> _futureUser;
  late Future<List<dynamic>> _futureCustomerList = Future.value([]);
  int _currentPage = 1;
  int _pageSize = 20;

  String? _token;

  @override
  void initState() {
    super.initState();
    _futureUser = fetchUser();
  }

  Future<Map<String, dynamic>> fetchUser() async {
    final response = await http.get(Uri.parse(
        'https://www.pqstec.com/InvoiceApps/Values/LogIn?UserName=admin@gmail.com&Password=admin1234&ComId=1'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final userName = responseData['UserName'];
      final token = responseData['Token'];

      // Store the token
      _token = token;

      // Check if the username is "admin"
      if (userName == "admin") {
        // Perform another request using the token
        await getCustomersList(token);

        // Return the response data
        return responseData;
      } else {
        throw Exception('Unauthorized user');
      }
    } else {
      throw Exception('Failed to process request');
    }
  }

  void showDialogMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue), // Information icon
              SizedBox(width: 8),
              Text('Warning'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> getCustomersList(String token) async {
    // Perform another request using the token to fetch customer list
    final response = await http.get(
      Uri.parse(
          'https://www.pqstec.com/InvoiceApps/Values/GetCustomerList?searchquery&pageNo=$_currentPage&pageSize=$_pageSize&SortyBy=Balance'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Handle the response
      final responseData = jsonDecode(response.body);
      final customerList = responseData['CustomerList'];
      if (customerList.isNotEmpty) {
        setState(() {
          _futureCustomerList = Future.value(customerList);
        });
      } else {
        setState(() {
          _currentPage--;
        });
        String message = "No more Customer are available";
        showDialogMessage(context, message);
      }
    } else {
      throw Exception('Failed to perform another request');
    }
  }

  void nextPage() {
    setState(() {
      _currentPage++;
    });
    getCustomersList(_token!);
  }

  void previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      getCustomersList(_token!);
    } else {
      String message = "You can not go back any more";
      showDialogMessage(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Customer List'),
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureCustomerList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    final customerList = snapshot.data!;
                    return ListView.builder(
                      itemCount: customerList.length,
                      itemBuilder: (context, index) {
                        final customer = customerList[index];
                        final String customerName = customer['Name'];
                        final String imagePath = customer['ImagePath'] ?? '';

                        return Column(
                          children: [
                            ListTile(
                              title: Text(customerName),
                              leading: imagePath.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        "https://www.pqstec.com/InvoiceApps$imagePath",
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetailsPage(
                                        customer: customer,
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(
                                    Icons.info), // Icon for "See Details"
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                        'Failed to load customer list: ${snapshot.error}');
                  }

                  return const Text(
                      'No customers found'); // Show this if no data is available
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      previousPage();
                    },
                    icon: const Icon(
                        Icons.arrow_back), // Icon for "Previous Page"
                  ),
                  IconButton(
                    onPressed: () {
                      nextPage();
                    },
                    icon:
                        const Icon(Icons.arrow_forward), // Icon for "Next Page"
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerDetailsPage extends StatelessWidget {
  final dynamic customer;

  const CustomerDetailsPage({Key? key, required this.customer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://www.pqstec.com/InvoiceApps${customer['ImagePath']}",
                    ),
                    radius: 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DefaultTabController(
              length: 2, // Number of tabs
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'About'),
                      Tab(text: 'Sales '),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: MediaQuery.of(context).size.height -
                        370, // Adjust the height as needed
                    child: TabBarView(
                      children: [
                        // First tab: About
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Name:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['Name'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.email,
                                        color: Colors.blue), // Email icon
                                    const SizedBox(width: 10),
                                    Text(
                                      customer['Email'] == null ||
                                              customer['Email'] == ""
                                          ? 'N/A'
                                          : customer['Email'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        color: Colors.blue), // Email icon
                                    const SizedBox(width: 10),
                                    Text(
                                      customer['Phone'] == null ||
                                              customer['Phone'] == ""
                                          ? 'N/A'
                                          : customer['Phone'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Notes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['Notes'] == null ||
                                          customer['Notes'] == ""
                                      ? 'N/A'
                                      : customer['Notes'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Customer Type:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['CustType'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Primary Address:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['PrimaryAddress'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Secondary Address:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['SecondaryAddress'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Parent Customer:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['Parent Customer'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Second tab: Sales Related
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Due:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['TotalDue'].toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Last Sales Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['LastSalesDate'] == ''
                                      ? 'N/A'
                                      : customer['LastSalesDate'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Last Invoice No:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['LastInvoiceNo'] == ""
                                      ? 'N/A'
                                      : customer['LastInvoiceNo'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Last Sold Product:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['LastSoldProduct'] == ""
                                      ? 'N/A'
                                      : customer['LastSoldProduct'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Total Sales Value:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['TotalSalesValue']
                                      .toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Total Sales Return Value:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['TotalSalesReturnValue']
                                      .toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Total Amount Back:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['TotalAmountBack']
                                      .toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Total Collection:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['TotalCollection']
                                      .toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Last Transaction Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  customer['LastTransactionDate'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
