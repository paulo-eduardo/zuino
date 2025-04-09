import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zuino/components/product_card.dart';
import 'package:zuino/database/products_database.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/screens/login_screen.dart';
import 'package:zuino/components/qr_code_reader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zuino/screens/edit_user_screen.dart';
import 'package:zuino/screens/out_of_stock_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuino/models/avatar_manager.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.title});

  final String title;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<dynamic> products = [];
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
      // Use addPostFrameCallback to schedule setState after the current build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // Force UI update by updating the avatar file reference
        });
      });
    }
  }

  Future<void> _loadProducts() async {
    final sortedProducts = await ProductsDatabase().getSortedProducts();
    setState(() {
      products = sortedProducts;
    });
  }

  Future<void> sendUrlToServer(String url) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processando recibo...'),
              ],
            ),
          );
        },
      );

      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/receipt/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      // Close loading dialog - ensure we're popping the dialog, not the entire screen
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

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

        // Save products to database
        await ProductsDatabase().saveProducts(productList);

        // Create a visual refresh effect
        if (mounted) {
          // Immediately load products to prevent black screen
          _loadProducts();

          // Show success message
          _showToast('Recibo salvo com sucesso.', Colors.green);
        }
      } else {
        _showToast('Erro: Falha ao conectar ao servidor.', Colors.red);
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
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

  Future<void> _clearAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Limpar todos os dados'),
            content: const Text(
              'Isso irá remover todos os produtos e recibos. Esta ação não pode ser desfeita. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Limpar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Clear products box
        final productsBox = await Hive.openBox('products');
        await productsBox.clear();

        // Clear receipts box
        final receiptsBox = await Hive.openBox('receipts');
        await receiptsBox.clear();

        // Reload products to update UI
        await _loadProducts();

        _showToast('Todos os dados foram limpos com sucesso.', Colors.green);
      } catch (e) {
        _showToast('Erro ao limpar dados: ${e.toString()}', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the latest user info to ensure we have the updated display name
    final user = FirebaseAuth.instance.currentUser;
    final screenTitle =
        user != null
            ? "Estoque de ${user.displayName ?? 'Usu&aacute;rio'}"
            : "Estoque";

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
              // Handle loading, error, and success states
              final outOfStockCount =
                  snapshot.hasData && !snapshot.hasError
                      ? snapshot.data!.length
                      : 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.inventory_2_outlined),
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
                  ),
                  if (outOfStockCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$outOfStockCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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
                      key: ValueKey('avatar_${_avatarManager.version}'),
                      radius: 20,
                      backgroundImage:
                          _avatarManager.avatarImageBytes != null
                              ? MemoryImage(_avatarManager.avatarImageBytes!)
                              : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Replace print with a comment or proper logging
                        // Consider implementing a proper logging solution in the future
                        // For now, we'll just force a rebuild with default avatar
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {});
                        });
                      },
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
                        // Force UI refresh to update the header with new name
                        setState(() {});
                      }
                    } else if (value == 'Sair') {
                      await _avatarManager.handleLogout();
                      await FirebaseAuth.instance.signOut();
                      Fluttertoast.showToast(
                        msg: 'Voc&ecirc; saiu com sucesso.',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: 'clearButton',
              onPressed: _clearAllData,
              backgroundColor: Colors.red,
              tooltip: 'Limpar todos os dados',
              child: const Icon(Icons.delete_forever),
            ),
            FloatingActionButton(
              heroTag: 'scanButton',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRCodeReader()),
                );
                if (!mounted) return;
                if (result != null) {
                  final url = result.toString();

                  // Check if receipt already exists before sending to server
                  final hasReceipt = await ReceiptsDatabase().hasReceipt(url);
                  if (hasReceipt) {
                    _showToast('Erro: Este recibo já foi lido.', Colors.red);
                    return; // Exit early if receipt already exists
                  }

                  // If receipt doesn't exist, proceed with sending to server
                  await sendUrlToServer(url);

                  // After successful processing, save the receipt URL
                  await ReceiptsDatabase().insertReceipt(url);
                }
              },
              child: const Icon(Icons.qr_code),
            ),
          ],
        ),
      ),
    );
  }
}
