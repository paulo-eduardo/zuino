import 'package:flutter/material.dart';
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
  late Box _shoppingListBox;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _logger.info('ShoppingListSection initialized');
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    try {
      _logger.info('Loading shopping list');
      _shoppingListBox = await Hive.openBox('shopping_list');
      _logger.info(
        'Shopping list box opened, keys: ${_shoppingListBox.keys.length}',
      );

      // Add a listener to the box to update the total amount when it changes
      _shoppingListBox.listenable().addListener(_calculateTotalAmount);

      // Calculate the initial total amount
      await _calculateTotalAmount();

      if (mounted) {
        setState(() {
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
    _shoppingListBox.listenable().removeListener(_calculateTotalAmount);
    super.dispose();
  }

  // Handle item quantity changes
  void _handleQuantityChanged() {
    _logger.info('Item quantity changed');

    // Recalculate the total amount when an item changes
    _calculateTotalAmount();

    if (widget.onListChanged != null) {
      widget.onListChanged!();
    }
  }

  Future<void> _calculateTotalAmount() async {
    try {
      final items = await _shoppingListDb.getAllItems();
      final total = await _productDb.calculateTotalPrice(items);

      if (mounted) {
        setState(() {
          _totalAmount = total;
        });
      }
      _logger.info('Updated total amount: $_totalAmount');
    } catch (e) {
      _logger.error('Error calculating total amount', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.info(
      'Building ShoppingListSection, isLoading: $_isLoading, hasError: $_hasError',
    );

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
            valueListenable: _shoppingListBox.listenable(),
            builder: (context, box, _) {
              _logger.info(
                'ValueListenableBuilder rebuilding, box keys: ${box.keys.length}',
              );

              final List<ShoppingItem> items = [];
              for (var key in box.keys) {
                _logger.info(
                  'Processing item with key: $key, value type: ${box.get(key).runtimeType}',
                );
                final data = box.get(key);
                if (data != null) {
                  try {
                    final item = ShoppingItem.fromMap(
                      Map<String, dynamic>.from(data),
                    );
                    items.add(item);
                  } catch (e) {
                    _logger.error('Error parsing item data for key $key', e);
                  }
                }
              }

              _logger.info('Processed ${items.length} shopping items');

              if (items.isEmpty) {
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
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    
                    // Calculate position in grid
                    final int row = index ~/ 3; // Integer division by 3 (crossAxisCount)
                    final int col = index % 3;  // Remainder when divided by 3
                    
                    // Determine which corners should be rounded
                    final bool roundTopLeft = row == 0 && col == 0;
                    final bool roundTopRight = row == 0 && col == 2;
                    final bool roundBottomLeft = (row == (items.length - 1) ~/ 3) && col == 0;
                    final bool roundBottomRight = (row == (items.length - 1) ~/ 3) && col == 2;
                    
                    return ShoppingItemCard(
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
