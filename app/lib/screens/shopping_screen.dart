import 'package:flutter/material.dart';
import 'package:zuino/components/page_header.dart';
import 'package:zuino/components/product_list_section.dart';
import 'package:zuino/components/receipt_scanner.dart';
import 'package:zuino/components/shopping_list_section.dart';
import 'package:zuino/components/speed_dial_fab.dart';
import 'package:zuino/database/database_cleaner.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/screens/analytics_screen.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/utils/toast_manager.dart'; // Add this import

class ShoppingScreen extends StatefulWidget {
  final bool showHeader;

  const ShoppingScreen({super.key, this.showHeader = true});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final ProductDatabase _productDb = ProductDatabase();
  final ReceiptsDatabase _receiptDb = ReceiptsDatabase();
  final _logger = Logger('ShoppingScreen');
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _shoppingListKey = GlobalKey<State<ShoppingListSection>>();
  final _shoppingListDb = ShoppingListDatabase();
  final _productListKey = GlobalKey<State<ProductListSection>>();

  // Method to handle receipt scanning
  void _scanReceipt() {
    final scanner = ReceiptScanner(
      context: context,
      onScanComplete: () {
        // Refresh your shopping list or perform other actions
        setState(() {
          // Refresh data
        });
      },
    );
    scanner.scanReceipt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar:
          widget.showHeader
              ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight + 30),
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  child: SafeArea(
                    child: PageHeader(
                      showBackButton: false,
                      showAvatar: true,
                      actionButton: IconButton(
                        icon: const Icon(
                          Icons.analytics,
                          color: Colors.blue,
                          size: 26.0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        tooltip: 'Análise de gastos',
                      ),
                      onAvatarChanged: () => setState(() {}),
                    ),
                  ),
                ),
              )
              : null,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add some spacing between header and content
                const SizedBox(height: 8),

                // Shopping List Section - Make sure it doesn't capture scroll events
                ShoppingListSection(key: _shoppingListKey),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Divider(color: Colors.grey),
                ),

                // Product List Section - Make sure it doesn't capture scroll events
                ProductListSection(key: _productListKey),

                // Bottom padding
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      // Replace the regular FloatingActionButton with SpeedDialFab
      floatingActionButton: SpeedDialFab(
        backgroundColor: Theme.of(context).primaryColor,
        mainIcon: Icons.add,
        items: [
          SpeedDialItem(
            icon: Icons.qr_code_scanner,
            label: 'Escanear Recibo',
            onTap: _scanReceipt,
            backgroundColor: Colors.green,
          ),
          SpeedDialItem(
            icon: Icons.delete_sweep,
            label: 'Limpar Produtos',
            backgroundColor: Colors.red,
            onTap: () {
              DatabaseCleaner(
                productDb: _productDb,
                receiptDb: _receiptDb,
              ).clearAllData(context);
            },
          ),
          SpeedDialItem(
            icon: Icons.delete_sweep,
            label: 'Limpar Lista',
            onTap: _showClearConfirmation,
            backgroundColor: Colors.red,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Refresh both sections
  Future<void> _refreshData() async {
    _logger.info('Refreshing shopping screen data');

    // Refresh shopping list
    _refreshShoppingList();

    // Refresh product list
    _refreshProductList();

    return Future.delayed(const Duration(milliseconds: 300));
  }

  // Refresh only the shopping list section
  void _refreshShoppingList() {
    _logger.info('Refreshing shopping list');
    if (_shoppingListKey.currentState != null) {
      setState(() {
        // This will force the shopping list section to rebuild
        _shoppingListKey.currentState!.setState(() {});
      });
    }
  }

  // Refresh only the product list section
  void _refreshProductList() {
    _logger.info('Refreshing product list');
    if (_productListKey.currentState != null) {
      setState(() {
        // This will force the product list section to rebuild
        _productListKey.currentState!.setState(() {});
      });
    }
  }

  // Show confirmation dialog for clearing the shopping list
  Future<void> _showClearConfirmation() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Limpar Lista de Compras'),
            content: const Text(
              'Tem certeza que deseja limpar toda a lista de compras?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldClear == true) {
      _clearShoppingList();
    }
  }

  // Clear the shopping list
  Future<void> _clearShoppingList() async {
    try {
      _logger.info('Clearing shopping list');

      // Call the database to clear the shopping list
      await _shoppingListDb.clearAll();

      _refreshShoppingList();

      // No need for success toast as the UI change is clearly visible
      // The shopping list will be empty, which is obvious feedback to the user
    } catch (e) {
      _logger.error('Error clearing shopping list', e);
      // Show error toast using ToastManager
      ToastManager.showError('Erro ao limpar lista: ${e.toString()}');
    }
  }
}
