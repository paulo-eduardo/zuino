import 'package:flutter/material.dart';
import 'package:zuino/components/page_header.dart';
import 'package:zuino/components/product_list_section.dart';
import 'package:zuino/components/receipt_scanner.dart';
import 'package:zuino/components/shopping_input_bar.dart';
import 'package:zuino/components/shopping_list_section.dart';
import 'package:zuino/components/shopping_search_modal.dart';
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
  final _logger = Logger('ShoppingScreen');
  final _shoppingListKey = GlobalKey<State<ShoppingListSection>>();
  final _shoppingListDb = ShoppingListDatabase();
  final _productListKey = GlobalKey<State<ProductListSection>>();

  // Add these new variables for search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Store the position of the menu button
  final GlobalKey _menuButtonKey = GlobalKey();

  // Method to handle receipt scanning
  void _scanReceipt() {
    final scanner = ReceiptScanner(context: context);
    scanner.scanReceipt();
  }

  // Update the _handleMenuPressed method to show a popup menu
  void _handleMenuPressed() {
    final RenderBox? renderBox =
        _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Calculate position for the popup
    final double left = position.dx;
    final double top =
        position.dy - 120; // Position it above the button with some padding

    // Show custom popup menu with improved styling
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, left + size.width, top + 120),
      items: [
        PopupMenuItem(
          value: 'scan',
          child: Row(
            children: const [
              Icon(Icons.qr_code_scanner, color: Colors.green),
              SizedBox(width: 12),
              Text('Escanear Nota', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear',
          child: Row(
            children: const [
              Icon(Icons.delete_sweep, color: Colors.red),
              SizedBox(width: 12),
              Text('Limpar Lista', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear_products',
          child: Row(
            children: const [
              Icon(Icons.delete_forever, color: Colors.orange),
              SizedBox(width: 12),
              Text('Limpar Produtos', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      elevation: 8.0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then((value) {
      if (value == 'clear') {
        _showClearConfirmation();
      } else if (value == 'scan') {
        _scanReceipt();
      } else if (value == 'clear_products') {
        _showClearProductsConfirmation();
      }
    });
  }

  // Update this method to show the search modal and use the logger instead of print
  void _handleSearchTap() {
    // Show the search modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Enable the modal to resize when the keyboard appears
      enableDrag: false,
      builder: (context) => const ShoppingSearchModal(),
    );
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
        bottom: false, // Don't apply safe area padding at the bottom
        child: Column(
          children: [
            Expanded(
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
                    const Divider(color: Colors.grey),

                    // Product List Section - Make sure it doesn't capture scroll events
                    ProductListSection(key: _productListKey),
                  ],
                ),
              ),
            ),

            // Add a container with the same color as the input bar to ensure safe area is colored
            Container(
              color: const Color(0xFF1E1E1E),
              child: SafeArea(
                top: false, // Don't apply safe area padding at the top
                child: ShoppingInputBar(
                  controller: _searchController,
                  onTap: _handleSearchTap,
                  onMenuPressed: _handleMenuPressed,
                  focusNode: _searchFocusNode,
                  hintText: "Eu quero comprar...",
                  menuButtonKey: _menuButtonKey, // Pass the key here
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      // Call the database to clear the shopping list
      await _shoppingListDb.clearAll();

      // No need for success toast as the UI change is clearly visible
      // The shopping list will be empty, which is obvious feedback to the user
    } catch (e) {
      _logger.error('Error clearing shopping list', e);
      // Show error toast using ToastManager
      ToastManager.showError('Erro ao limpar lista: ${e.toString()}');
    }
  }

  // Show confirmation dialog for clearing all products
  Future<void> _showClearProductsConfirmation() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Limpar Todos os Produtos'),
            content: const Text(
              'Tem certeza que deseja limpar todos os produtos e notas fiscais? Esta ação não pode ser desfeita.',
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
      _clearAllProducts();
    }
  }

  // Clear all products and receipts
  Future<void> _clearAllProducts() async {
    try {
      // Import the necessary databases
      final productDb = ProductDatabase();
      final receiptDb = ReceiptsDatabase(); // You'll need to create this import

      // Clear all products
      await productDb.clearAll();

      // Clear all receipts
      await receiptDb.clearAll();

      // Show success toast
      ToastManager.showSuccess('Todos os produtos e notas foram removidos');
    } catch (e) {
      _logger.error('Error clearing products and receipts', e);
      // Show error toast using ToastManager
      ToastManager.showError('Erro ao limpar produtos: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    // Dispose of the controller and focus node
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
