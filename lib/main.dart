import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_gtr/customer_details.dart';
import 'package:http/http.dart' as http;

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
  List<dynamic> _customerList = []; // Store the current customer list

  late Future<List<dynamic>> _futureCustomerList = Future.value([]);
  int _currentPage = 1;
  int _pageSize = 20;

  String? _token;
  ScrollController _scrollController =
      ScrollController(); // Step 1: Add ScrollController

  @override
  void initState() {
    super.initState();
    _futureUser = fetchUser();

    // Step 2: Add listener to ScrollController for infinite scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        nextPage();
      } else if (_scrollController.position.pixels ==
          _scrollController.position.minScrollExtent) {
        previousPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the ScrollController
    super.dispose();
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
      }
    } else {
      throw Exception('Failed to perform another request');
    }
  }

  Future<void> nextPage() async {
    final customerList =
        await _futureCustomerList; // Wait for the future to complete
    if (customerList.isNotEmpty) {
      // Check if the list is not empty
      setState(() {
        _currentPage++;
      });
      getCustomersList(_token!);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      await getCustomersList(_token!);
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
                      controller:
                          _scrollController, // Step 3: Attach ScrollController
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
          ],
        ),
      ),
    );
  }
}


