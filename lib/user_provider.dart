import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class User {
  final String userName;
  final String token;

  User({required this.userName, required this.token});
}
class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  Future<void> loginUser() async {
    final response = await http.get(Uri.parse(
        'https://www.pqstec.com/InvoiceApps/Values/LogIn?UserName=admin@gmail.com&Password=admin1234&ComId=1'));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final userName = responseData['UserName'];
      final token = responseData['Token'];

      _user = User(userName: userName, token: token);
      notifyListeners();
    } else {
      throw Exception('Failed to log in');
    }
  }
}