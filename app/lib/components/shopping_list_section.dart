import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/shopping_list_database.dart';
import '../models/shopping_item.dart';
import '../utils/logger.dart';
import '../components/shopping_item_card.dart';
import '../database/product_database.dart';

class ShoppingListSection extends StatefulWidget {
  final VoidCallback? onListChanged;

  const ShoppingListSection({super.key, this.onListChanged});

  @override
  State<ShoppingListSection> createState() => _ShoppingListSectionState();
}

class _ShoppingListSectionState extends State<ShoppingListSection> {
  final ShoppingListDatabase _shoppingListDb = ShoppingListDatabase();
  final ProductDatabase _productDb = ProductDatabase();
  final Logger _logger = Logger('ShoppingListSection');

  bool _isLoading = true;
  bool _hasError = false;
  late ValueListenable<Box<dynamic>> _shoppingListListenable;
  double _totalAmount = 0.0;
  List<ShoppingItem> _items = []; // Added to store items

  @override
  void initState() {
    super.initState();
    _initializeShoppingList();
  }

  Future<void> _initializeShoppingList() async {
    try {
      final listenable = await _shoppingListDb.getListenable();

      if (mounted) {
        setState(() {
          _shoppingListListenable = listenable;

          // Add a listener that will update the UI when the box changes
          _shoppingListListenable.addListener(() {
            // This will trigger a rebuild of the ValueListenableBuilder
            // but we'll handle the data fetching more efficiently
            if (mounted) {
              _loadShoppingList();
            }
          });
        });

        // Now that we have the listenable, load the shopping list
        _loadShoppingList();
      }
    } catch (e) {
      _logger.error('Error initializing shopping list listenable', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadShoppingList() async {
    try {
      // Get the items directly without using FutureBuilder in the UI
      final items = await _shoppingListDb.getAllItemsSortedById();

      // Calculate the total amount
      final total = await _productDb.calculateTotalPrice(items);

      if (mounted) {
        setState(() {
          _items = items;
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error loading shopping list', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    _shoppingListListenable.removeListener(() {
      if (mounted) {
        _loadShoppingList();
      }
    });
    super.dispose();
  }

  // Handle item quantity changes
  void _handleQuantityChanged() {
    // Recalculate the total amount when an item changes
    _calculateTotalAmount();

    if (widget.onListChanged != null) {
      widget.onListChanged!();
    }
  }

  Future<void> _calculateTotalAmount() async {
    try {
      final total = await _productDb.calculateTotalPrice(_items);

      if (mounted) {
        setState(() {
          _totalAmount = total;
        });
      }
    } catch (e) {
      _logger.error('Error calculating total amount', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lista de Compras',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'R\$ ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content based on state
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Erro ao carregar lista de compras',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadShoppingList,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          )
        else
          ValueListenableBuilder(
            valueListenable: _shoppingListListenable,
            builder: (context, box, _) {
              // Use the items we've already loaded in state
              if (_items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Sua lista de compras está vazia',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    // Calculate position in grid
                    final int row =
                        index ~/ 3; // Integer division by 3 (crossAxisCount)
                    final int col = index % 3; // Remainder when divided by 3

                    // Determine which corners should be rounded
                    final bool roundTopLeft = row == 0 && col == 0;
                    final bool roundTopRight = row == 0 && col == 2;
                    final bool roundBottomLeft =
                        (row == (_items.length - 1) ~/ 3) && col == 0;
                    final bool roundBottomRight =
                        (row == (_items.length - 1) ~/ 3) && col == 2;

                    return ShoppingItemCard(
                      key: ValueKey(item.productCode),
                      item: item,
                      onQuantityChanged: _handleQuantityChanged,
                      roundTopLeft: roundTopLeft,
                      roundTopRight: roundTopRight,
                      roundBottomLeft: roundBottomLeft,
                      roundBottomRight: roundBottomRight,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
