import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mercadinho/components/product_card.dart';
import 'package:mercadinho/database/products_database.dart';
import 'package:mercadinho/database/receipts_database.dart';
import 'package:mercadinho/screens/login_screen.dart';
import 'package:mercadinho/components/qr_code_reader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.title});

  final String title;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
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
        Uri.parse('${dotenv.env['API_BASE_URL']}/receipt/scan'),
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
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
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
          child: Text(widget.title), // Use dynamic title
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final additionalPadding = constraints.maxHeight * 0.05;
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0 + additionalPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: ProductCard(
                  codigo: product['codigo'],
                  name: product['name'],
                  unit: product['unit'],
                  unitValue: product['unitValue'],
                  quantity: product['quantity'],
                  total: product['unitValue'] * product['quantity'],
                  used: product['used'] ?? 0,
                  onStockUpdated: _loadProducts,
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
