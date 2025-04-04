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
import 'package:mercadinho/screens/edit_user_screen.dart';
import 'package:mercadinho/screens/out_of_stock_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:mercadinho/models/avatar_manager.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.title});

  final String title;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<dynamic> products = [];
  File? _avatarFile;
  final _avatarManager = AvatarManager();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _avatarManager.loadAvatar();
    _avatarManager.addListener(_onAvatarChanged);
  }

  @override
  void dispose() {
    _avatarManager.removeListener(_onAvatarChanged);
    super.dispose();
  }

  void _onAvatarChanged() {
    if (mounted) {
      setState(() {
        _avatarFile = _avatarManager.avatarFile;
      });
    }
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
        final productList =
            (jsonDecode(response.body) as List).map((product) {
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
    final user = FirebaseAuth.instance.currentUser;
    final screenTitle =
        user != null ? "Estoque de ${user.displayName}" : "Estoque";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent back arrow from showing
        toolbarHeight: 70, // Make AppBar taller
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            screenTitle,
            style: const TextStyle(fontSize: 20), // Slightly larger title
          ),
        ),
        actions: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: ProductsDatabase().getOutOfStockProducts(),
            builder: (context, snapshot) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: snapshot.hasData && snapshot.data!.isNotEmpty,
                  label: snapshot.hasData && snapshot.data!.isNotEmpty 
                      ? Text(snapshot.data!.length.toString())
                      : null,
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                tooltip: 'Produtos em falta',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OutOfStockScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadProducts();
                  }
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              if (user != null) {
                return PopupMenuButton<String>(
                  icon: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: CircleAvatar(
                      key: ValueKey('avatar_${_avatarManager.timestamp}'),
                      radius: 20,
                      backgroundImage:
                          _avatarFile != null
                              ? FileImage(_avatarFile!, scale: 1.0)
                              : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                    ),
                  ),
                  offset: const Offset(0, 50),
                  onSelected: (value) async {
                    if (value == 'Editar') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditUserScreen(),
                        ),
                      );
                      if (!mounted) return;
                      if (result == true) {
                        // Reload avatar when returning from edit screen
                        _avatarManager.loadAvatar();
                      }
                    } else if (value == 'Sair') {
                      await _avatarManager.clearAvatar();
                      await FirebaseAuth.instance.signOut();
                      Fluttertoast.showToast(
                        msg: 'Você saiu com sucesso.',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                      if (!mounted) return;
                      setState(() {});
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'Editar',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(value: 'Sair', child: Text('Sair')),
                      ],
                );
              } else {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/default_avatar.png'),
                      backgroundColor: Colors.grey,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final additionalPadding = constraints.maxHeight * 0.05;
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              8.0,
              8.0,
              8.0,
              80.0 + additionalPadding,
            ),
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
          if (!mounted) return;
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
        child: const Icon(Icons.qr_code),
      ),
    );
  }
}
