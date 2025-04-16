import 'package:flutter/material.dart';
import 'package:zuino/components/page_header.dart';
import 'package:zuino/components/product_list_section.dart';
import 'package:zuino/components/shopping_list_section.dart';
import 'package:zuino/components/speed_dial_fab.dart';
import 'package:zuino/components/receipt_scanner.dart';
import 'package:zuino/screens/analytics_screen.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/database/shopping_list_database.dart';

class ShoppingScreen extends StatefulWidget {
  final bool showHeader;

  const ShoppingScreen({super.key, this.showHeader = true});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _logger = Logger('ShoppingScreen');
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _shoppingListKey = GlobalKey<State<ShoppingListSection>>();
  final _shoppingListDb = ShoppingListDatabase();

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

  // Method to add a new item manually
  void _addNewItem() {
    // Your existing code to add a new item
    // This might open a dialog or navigate to another screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar:
          widget.showHeader
              ? PreferredSize(
                preferredSize: const Size.fromHeight(
                  kToolbarHeight + 30,
                ), // Reduced from +40 to +20
                child: FutureBuilder<int>(
                  future: _shoppingListDb.getItemCount(),
                  builder: (context, snapshot) {
                    final itemCount = snapshot.data ?? 0;
                    final subtitle =
                        itemCount > 0
                            ? '$itemCount ${itemCount == 1 ? 'item' : 'itens'} na lista'
                            : 'Sua lista está vazia';

                    return AppBar(
                      backgroundColor: const Color(0xFF1E1E1E),
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      toolbarHeight:
                          kToolbarHeight + 20, // Explicitly set toolbar height
                      flexibleSpace: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 4,
                          ), // Add a small bottom padding
                          child: PageHeader(
                            title: "Lista de Compras",
                            subtitle: subtitle,
                            showBackButton: false,
                            actionButton: IconButton(
                              icon: const Icon(
                                Icons.analytics,
                                color: Colors.blue,
                                size: 26.0, // Slightly smaller icon
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AnalyticsScreen(),
                                  ),
                                );
                              },
                              tooltip: 'Análise de gastos',
                            ),
                            onAvatarChanged: () => setState(() {}),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
              : null,
      body: SafeArea(
        child: Column(
          children: [
            // Add some spacing between header and content
            const SizedBox(height: 8),

            // Scrollable content section
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shopping List Section
                      ShoppingListSection(
                        key: _shoppingListKey,
                        title: 'Itens na Lista',
                        onListUpdated: _refreshShoppingList,
                      ),

                      // Divider
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Divider(color: Colors.grey),
                      ),

                      // Product List Section
                      ProductListSection(
                        title: 'Produtos Disponíveis',
                        onListUpdated: _refreshShoppingList,
                      ),

                      // Bottom padding
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            icon: Icons.add_shopping_cart,
            label: 'Adicionar Item',
            onTap: _addNewItem,
            backgroundColor: Colors.blue,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Refresh both sections
  Future<void> _refreshData() async {
    _logger.info('Refreshing shopping screen data');
    setState(() {
      // Force rebuild of both sections
    });
    _refreshShoppingList();
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

      await _shoppingListDb.clearAll();
      _refreshShoppingList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista de compras limpa com sucesso')),
        );
      }
    } catch (e) {
      _logger.error('Error clearing shopping list', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar lista: ${e.toString()}')),
        );
      }
    }
  }
}
