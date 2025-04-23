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
import 'package:zuino/utils/toast_manager.dart';
import '../components/shopping_speed_dial.dart';

class ShoppingScreen extends StatefulWidget {
  final bool showHeader;

  const ShoppingScreen({super.key, this.showHeader = true});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _shoppingListKey = GlobalKey<State<ShoppingListSection>>();
  final _productListKey = GlobalKey<State<ProductListSection>>();

  // Add these new variables for search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _menuButtonKey = GlobalKey();
  bool _isMenuOpen = false;
  Offset _menuPosition = Offset.zero;

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

  void _toggleMenu() {
    final RenderBox renderBox =
        _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    setState(() {
      _menuPosition = position;
      _isMenuOpen = true;
    });
  }

  void _handleScanReceipt() {
    // Close the menu first
    setState(() {
      _isMenuOpen = false;
    });

    ReceiptScanner(context: context).scanReceipt();
  }

  void _handleClearShoppingList() async {
    setState(() {
      _isMenuOpen = false;
    });
    try {
      await ShoppingListDatabase().clearAll();
      ToastManager.showSuccess("Sua lista de compras esta limpa");
    } catch (e) {
      ToastManager.showError(
        "Erro ao limpar a lista de compras: ${e.toString()}",
      );
    }
  }

  void _handleClearProducts() async {
    setState(() {
      _isMenuOpen = false;
    });
    try {
      await ProductDatabase().clearAll();
      await ReceiptsDatabase().clearAll();
      await ShoppingListDatabase().clearAll();
      ToastManager.showSuccess("Produtos e Recibos limpos");
    } catch (e) {
      ToastManager.showError(
        "Erro ao limpar os produtos e recibos: ${e.toString()}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
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
        body: Stack(
          children: [
            // Main content
            Column(
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
                      focusNode: _searchFocusNode,
                      onMenuPressed: _toggleMenu,
                      menuButtonKey: _menuButtonKey,
                    ),
                  ),
                ),
              ],
            ),

            // Speed dial menu (overlay)
            if (_isMenuOpen)
              ShoppingSpeedDial(
                isOpen: _isMenuOpen,
                onToggle: (isOpen) => setState(() => _isMenuOpen = isOpen),
                anchorPosition: _menuPosition,
                items: [
                  ShoppingSpeedDialItem(
                    icon: Icons.receipt_outlined,
                    label: 'Escanear recibo',
                    onTap: _handleScanReceipt,
                  ),
                  ShoppingSpeedDialItem(
                    icon: Icons.cleaning_services_outlined,
                    label: 'Limpar lista de compras',
                    onTap: _handleClearShoppingList,
                  ),
                  ShoppingSpeedDialItem(
                    icon: Icons.delete_outline,
                    label: 'Limpar tudo',
                    onTap: _handleClearProducts,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the controller and focus node
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
