import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zuino/components/item_card.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/screens/login_screen.dart';
import 'package:zuino/components/qr_code_reader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'dart:async'; // Make sure this import is at the top of your file
import 'package:http/http.dart' as http;
import 'package:zuino/screens/edit_user_screen.dart';
import 'package:zuino/screens/out_of_stock_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuino/models/avatar_manager.dart';
import 'package:zuino/database/inventory_database.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/screens/analytics_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.title});

  final String title;

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Map<String, dynamic>> products = [];
  final _avatarManager = AvatarManager();
  final _logger = Logger('StockScreen'); // Add this line to define the logger
  bool isLoading = true;

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
    try {
      setState(() {
        isLoading = true;
      });

      // Get only in-stock inventory items
      final inventoryItems = await InventoryDatabase().getInStockItems();

      // Sort the in-stock items alphabetically by name
      inventoryItems.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      // Debug log to check what's coming from the database
      _logger.info(
        'Loaded ${inventoryItems.length} in-stock products from inventory',
      );
      for (var item in inventoryItems) {
        _logger.info('Product: ${item['name']} - Stock: ${item['stock']}');
      }

      if (mounted) {
        setState(() {
          products = List<Map<String, dynamic>>.from(inventoryItems);
          isLoading = false;
        });

        // Additional logging after state update
        _logger.info('In-stock products loaded. Count: ${products.length}');
        for (var item in products) {
          _logger.info(
            'Updated product: ${item['name']} - Stock: ${item['stock']}',
          );
        }
      }
    } catch (e) {
      _logger.error('Error loading in-stock products: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showToast('Erro ao carregar produtos: ${e.toString()}', Colors.red);
      }
    }
  }

  // Add the delete product method
  Future<void> _deleteProduct(String codigo, String name) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Produto'),
            content: Text('Tem certeza que deseja excluir "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        _logger.info('Deleting product with code: $codigo');

        // Use removeItem to delete the product from inventory
        await InventoryDatabase().removeItem(codigo);

        _logger.info('Product deleted successfully');

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto excluído com sucesso')),
        );

        // Reload the list
        _loadProducts();
      } catch (e) {
        _logger.error('Error deleting product', e);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir produto: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> sendUrlToServer(String url) async {
    if (!mounted) return;

    // Show a simple loading indicator in the bottom of the screen
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Processando recibo...'),
          ],
        ),
        duration: Duration(
          seconds: 30,
        ), // Long duration, we'll dismiss it manually
      ),
    );

    try {
      // First check if receipt already exists in database
      final hasReceipt = await ReceiptsDatabase().hasReceipt(url);

      if (!mounted) return;

      if (hasReceipt) {
        // Hide the loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        // Show error message
        _showToast(
          'Este recibo já foi processado anteriormente.',
          Colors.orange,
        );
        return;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/receipt/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract receipt data
        final receiptData = responseData['receipt'];
        final items = responseData['items'] as List;

        // Format items for both databases in a single loop
        final List<Map<String, dynamic>> inventoryItems = [];
        final List<Map<String, dynamic>> receiptItems = [];

        for (var item in items) {
          try {
            // Parse numeric values safely
            final double quantity = _safeParseDouble(item['quantity']);
            final double unitValue = _safeParseDouble(item['unitValue']);
            final double total = quantity * unitValue;

            // Format for inventory database
            inventoryItems.add({
              'codigo': item['codigo'],
              'name': item['name'],
              'unit': item['unit'],
              'lastUnitValue': unitValue,
              'stock': quantity,
              'category': item['category'] ?? 'Outros',
            });

            // Format for receipt database
            receiptItems.add({
              'productCode': item['codigo'],
              'quantity': quantity.toString(),
              'unit': item['unit'],
              'unitValue': unitValue.toString(),
              'total': total.toString(),
            });
          } catch (e) {
            // Log error and continue with next item
            _logger.error(
              'Error processing item: ${item['name'] ?? 'Unknown'} - $e',
            );
            continue;
          }
        }

        // Update snackbar to show we're saving data
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Atualizando estoque...'),
                ],
              ),
              duration: Duration(
                seconds: 30,
              ), // Long duration, we'll dismiss it manually
            ),
          );
        }

        // Parse date from string to DateTime
        final receiptDate = DateTime.parse(receiptData['date']);

        // Save receipt to database using URL as the unique identifier
        await ReceiptsDatabase().saveReceipt(
          url: receiptData['url'],
          store: receiptData['store'],
          date: receiptDate,
          totalAmount: double.parse(receiptData['totalAmount'].toString()),
          paymentMethod: receiptData['paymentMethod'],
          items: receiptItems,
        );

        // Update inventory with receipt items
        await InventoryDatabase().updateFromReceipt(inventoryItems);

        if (!mounted) return;

        // Hide the loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        // Show a simple toast notification of success
        _showToast(
          'Recibo processado com sucesso. ${items.length} itens adicionados.',
          Colors.green,
        );

        // Reload products immediately after updating inventory
        await _loadProducts();
      } else {
        if (!mounted) return;

        // Hide the loading indicator
        scaffoldMessenger.hideCurrentSnackBar();

        // Show error message
        _showToast('Erro: Falha ao conectar ao servidor.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;

      // Hide the loading indicator
      scaffoldMessenger.hideCurrentSnackBar();

      // Show error message with details
      _showToast(
        'Erro: Falha ao processar recibo. ${e.toString()}',
        Colors.red,
      );
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
          (dialogContext) => AlertDialog(
            title: const Text('Limpar todos os dados'),
            content: const Text(
              'Isso irá remover todos os produtos e recibos. Esta ação não pode ser desfeita. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Limpar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Check if widget is still mounted before showing dialog
        if (!mounted) return;

        // Show loading indicator
        final loadingDialogCompleter = Completer<Function>();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            // Store the context in the completer to close it later
            loadingDialogCompleter.complete(() {
              if (Navigator.canPop(dialogContext)) {
                Navigator.of(dialogContext).pop();
              }
            });

            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Limpando dados...'),
                ],
              ),
            );
          },
        );

        // Clear inventory box
        final inventoryBox = await Hive.openBox('inventory');
        await inventoryBox.clear();

        // Clear receipts box
        final receiptsBox = await Hive.openBox('receipts');
        await receiptsBox.clear();

        // Check if widget is still mounted before closing dialog
        if (!mounted) return;

        // Close loading dialog using the stored function
        final closeDialog = await loadingDialogCompleter.future;
        closeDialog(); // Now this will work because closeDialog is a Function

        // Reload products to update UI
        await _loadProducts();

        // Check if widget is still mounted before showing toast
        if (!mounted) return;

        _showToast('Todos os dados foram limpos com sucesso.', Colors.green);
      } catch (e) {
        // Check if widget is still mounted before closing dialog and showing toast
        if (!mounted) return;

        _showToast('Erro ao limpar dados: ${e.toString()}', Colors.red);
      }
    }
  }

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    try {
      return double.parse(value.toString());
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _scanQRCode() async {
    try {
      // Create a completer to manage the loading dialog
      final loadingDialogCompleter = Completer<void>();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Processando QR Code..."),
              ],
            ),
          );
        },
      ).then((_) => loadingDialogCompleter.complete());

      // Function to close dialog
      void closeDialog() {
        if (!loadingDialogCompleter.isCompleted) {
          Navigator.of(context, rootNavigator: true).pop();
          loadingDialogCompleter.complete();
        }
      }

      // Rest of your QR code scanning logic...
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRCodeReader()),
      );

      if (!mounted) return;

      if (result != null) {
        final url = result.toString();

        // Process the URL immediately without showing confirmation dialog
        await sendUrlToServer(url);
      }

      // When done, close dialog and reload products
      await loadingDialogCompleter.future;
      closeDialog();
      await _loadProducts();
    } catch (e) {
      _logger.error('Error scanning QR code: $e');
      // Handle error...
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
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Análise de Gastos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future:
                InventoryDatabase()
                    .getOutOfStockItems(), // Changed from ProductsDatabase().getOutOfStockProducts()
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
      body: GestureDetector(
        // Add swipe gesture detection
        onHorizontalDragEnd: (details) {
          // Check if the swipe is from right to left (negative velocity)
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -300) {
            // Navigate to out of stock screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OutOfStockScreen()),
            ).then((result) {
              if (result == true) {
                _loadProducts();
              }
            });
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? const Center(
                  child: Text(
                    'Nenhum produto no estoque',
                    style: TextStyle(fontSize: 18),
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
                    120,
                  ), // Increased bottom padding to 120
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two cards per row
                    childAspectRatio:
                        0.85, // Adjust this value to control card height
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: ItemCard(
                        name: product['name'],
                        stock: product['stock'],
                        codigo: product['codigo'],
                        unit: product['unit'], // Pass the unit if available
                        onItemUpdated: () {
                          // Refresh the items list
                          _loadProducts();
                        },
                      ),
                    );
                  },
                );
          },
        ),
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
              onPressed: _scanQRCode,
              backgroundColor: Colors.blue,
              tooltip: 'Escanear recibo',
              child: const Icon(Icons.qr_code_scanner),
            ),
          ],
        ),
      ),
    );
  }
}
