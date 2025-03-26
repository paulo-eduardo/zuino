import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mercadinho/components/qr_code_reader.dart';
import 'package:mercadinho/components/product_icon.dart';
import 'package:mercadinho/database/receipts_database.dart';
import 'package:mercadinho/database/products_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
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
    final box = await Hive.openBox('products');
    setState(() {
      products = box.values.toList();
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
        final box = await Hive.openBox('products');
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
          final existingProduct = box.get(product['codigo']);
          if (existingProduct != null) {
            product['quantity'] += existingProduct['quantity'];
          }
          box.put(product['codigo'], product);
        }
        _loadProducts();
      } else {
        print('Failed to send URL to server');
      }
    } catch (e) {
      print('Error sending URL to server: $e');
    }
  }

  void _showToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // Change to LONG to make the toast live longer
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2, // Increase the duration for iOS
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRCodeReader()),
          );
          if (result != null) {
            final url = result.toString();
            final hasReceipt = await ReceiptsDatabase().hasReceipt(url);
            if (hasReceipt) {
              _showToast('Erro: Este recibo já foi lido.', Colors.red);
            } else {
              await ReceiptsDatabase().insertReceipt(url);
              await sendUrlToServer(url);
              _showToast('Recibo salvo com sucesso.', Colors.green);
            }
          }
        },
        child: Icon(Icons.qr_code),
      ),
    );
  }
}
