import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/shopping_list_database.dart';
import '../models/shopping_item.dart';
import '../utils/logger.dart';
import '../components/shopping_item_card.dart';

class ShoppingListSection extends StatefulWidget {
  final VoidCallback? onListChanged;

  const ShoppingListSection({super.key, this.onListChanged});

  @override
  State<ShoppingListSection> createState() => _ShoppingListSectionState();
}

class _ShoppingListSectionState extends State<ShoppingListSection> {
  final ShoppingListDatabase _shoppingListDb = ShoppingListDatabase();
  final Logger _logger = Logger('ShoppingListSection');

  bool _isLoading = true;
  bool _hasError = false;
  late Box _shoppingListBox;

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
  Widget build(BuildContext context) {
    _logger.info(
      'Building ShoppingListSection, isLoading: $_isLoading, hasError: $_hasError',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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
              // Clear list button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Limpar lista'),
                          content: const Text(
                            'Tem certeza que deseja limpar toda a lista de compras?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _shoppingListDb.clearAll();
                                if (widget.onListChanged != null) {
                                  widget.onListChanged!();
                                }
                              },
                              child: const Text('Limpar'),
                            ),
                          ],
                        ),
                  );
                },
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
                  final item = ShoppingItem.fromMap(
                    Map<String, dynamic>.from(data),
                  );
                  items.add(item);
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
                    childAspectRatio: 1.0, // Perfect square
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    // Use your own custom widget or direct implementation here
                    // instead of ShoppingItemCard
                    return Card(child: ShoppingItemCard(item: item));
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
