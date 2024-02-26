import 'package:flutter/material.dart';
import 'package:flutter_application_gtr/customer_details.dart';
import 'package:flutter_application_gtr/customer_provider.dart';
import 'package:flutter_application_gtr/user_provider.dart';

import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: const MaterialApp(
        home: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ScrollController _scrollController = ScrollController();
  late UserProvider _userProvider;
  late CustomerProvider _customerProvider;
  late String? _token;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    fetchData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      await _userProvider.loginUser();
      _token = _userProvider.user?.token;
      if (_token != Null) {
        await _customerProvider.fetchCustomers(_token!);
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _customerProvider.fetchCustomers(_token!, nextPage: true);
    } else if (_scrollController.position.pixels ==
        _scrollController.position.minScrollExtent) {
      _customerProvider.fetchCustomers(_token!, previousPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer List'),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            final customerList = customerProvider.customers;
            return ListView.builder(
              controller: _scrollController,
              itemCount: customerList.length,
              itemBuilder: (context, index) {
                final customer = customerList[index];
                return ListTile(
                  title: Text(customer.name),
                  leading: customer.imagePath != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            "https://www.pqstec.com/InvoiceApps${customer.imagePath}",
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
                    child: const Icon(Icons.info),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
