import 'package:flutter/material.dart';
import 'package:zuino/components/shopping_item_card.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/shopping_list_database.dart';
import 'package:zuino/models/shopping_item.dart';
import 'package:zuino/utils/logger.dart';

class ShoppingListSection extends StatefulWidget {
  final String title;
  final VoidCallback? onListUpdated;

  const ShoppingListSection({
    super.key,
    required this.title,
    this.onListUpdated,
  });

  @override
  State<ShoppingListSection> createState() => _ShoppingListSectionState();
}

class _ShoppingListSectionState extends State<ShoppingListSection> {
  final _logger = Logger('ShoppingListSection');
  final _shoppingListDb = ShoppingListDatabase();
  final _productDb = ProductDatabase();
  List<ShoppingItem> _items = [];
  bool _isLoading = true;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load items first
      final items = await _shoppingListDb.getAllItems();

      // Update UI with items immediately
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }

      // Calculate total price in parallel
      _calculateTotalPrice(items);
    } catch (e) {
      _logger.error('Error loading shopping list items', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Separate method to calculate total price
  Future<void> _calculateTotalPrice(List<ShoppingItem> items) async {
    try {
      final totalPrice = await _productDb.calculateTotalPrice(items);

      if (mounted) {
        setState(() {
          _totalPrice = totalPrice;
        });
      }
    } catch (e) {
      _logger.error('Error calculating total price', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Total price
              Text(
                'Total: R\$ ${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ),

        // Loading indicator or grid
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum item na lista de compras',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
            : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ShoppingItemCard(
                    item: item,
                    key: ValueKey(item.productCode),
                  );
                },
              ),
            ),
      ],
    );
  }
}
