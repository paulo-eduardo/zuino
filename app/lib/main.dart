import 'package:flutter/material.dart';
import 'package:app/components/qr_code_reader.dart';
import 'package:app/components/product_icon.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/database_helper.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final dbHelper = DatabaseHelper();
    final productList = await dbHelper.getProducts();
    setState(() {
      products = productList;
    });
  }

  Future<void> sendUrlToServer(String url) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.68.105:3000/receipt/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );
      if (response.statusCode == 200) {
        final dbHelper = DatabaseHelper();
        await dbHelper.insertReceipt(url);
        final productList = (jsonDecode(response.body) as List).map((product) {
          return {
            'codigo': product['codigo'],
            'name': product['name'],
            'unit': product['unit'],
            'unitValue': double.parse(product['unitValue'].toString()),
            'quantity': double.parse(product['quantity'].toString()),
            'used': 0.0,
          };
        }).toList();
        for (var product in productList) {
          await dbHelper.insertOrUpdateProduct(product);
        }
        _loadProducts();
      } else {
        print('Failed to send URL to server');
      }
    } catch (e) {
      print('Error sending URL to server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.grey[900]),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductIcon(
                    name: product['name'],
                    unit: product['unit'],
                    unitValue: product['unitValue'],
                    quantity: product['quantity'],
                    total: product['unitValue'] * product['quantity'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final url = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRCodeReader()),
          );
          if (url != null) {
            await sendUrlToServer(url);
          }
        },
        tooltip: 'Scan QR Code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
