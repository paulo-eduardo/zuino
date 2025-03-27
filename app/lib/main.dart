import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mercadinho/components/qr_code_reader.dart';
import 'package:mercadinho/components/product_card.dart'; // Update import
import 'package:mercadinho/database/receipts_database.dart';
import 'package:mercadinho/database/products_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mercadinho/screens/product_detail_screen.dart'; // Add this import

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2C2C2C), // Neutral dark tone
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2C), // Same neutral dark tone for the header
          elevation: 0, // Flat design
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(title: 'Dispensa'),
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
        Uri.parse('http://192.168.68.100:3000/receipt/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );
      if (response.statusCode == 200) {
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
        await ProductsDatabase().saveProducts(productList);
        _loadProducts();
        _showToast('Recibo salvo com sucesso.', Colors.green);
      } else {
        _showToast('Erro: Falha ao conectar ao servidor.', Colors.red);
      }
    } catch (e) {
      _showToast('Erro: Falha ao conectar ao servidor.', Colors.red);
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
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Add functionality for avatar icon if needed
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final additionalPadding = constraints.maxHeight * 0.05; // 5% of screen height
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0 + additionalPadding), // Add dynamic bottom padding
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1, // Change aspect ratio to make items square
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque, // Ensure taps are only detected on the card itself
                child: ProductCard(
                  codigo: product['codigo'], // Use codigo here
                  name: product['name'],
                  unit: product['unit'],
                  unitValue: product['unitValue'],
                  quantity: product['quantity'],
                  total: product['unitValue'] * product['quantity'],
                  used: product['used'] ?? 0,
                  onStockUpdated: _loadProducts, // Pass the callback to reload products
                ),
              );
            },
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
              // Save receipt only if backend request is successful
              await sendUrlToServer(url);
              if (await ReceiptsDatabase().hasReceipt(url)) {
                await ReceiptsDatabase().insertReceipt(url);
              }
            }
          }
        },
        child: Icon(Icons.qr_code),
      ),
    );
  }
}
