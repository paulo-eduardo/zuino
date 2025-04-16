import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zuino/screens/edit_product_screen.dart';
import 'package:zuino/database/inventory_database.dart';
import 'package:zuino/utils/logger.dart';

class ItemCard extends StatefulWidget {
  final String name;
  final double stock;
  final String codigo;
  final VoidCallback? onItemUpdated;
  final String? unit;
  final double? price;

  const ItemCard({
    Key? key,
    required this.name,
    required this.stock,
    required this.codigo,
    this.onItemUpdated,
    this.unit,
    this.price,
  }) : super(key: key);

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  final _logger = Logger('ItemCard');
  final _inventoryDb = InventoryDatabase();

  @override
  Widget build(BuildContext context) {
    // Format stock with unit if available
    final formattedStock =
        widget.unit != null
            ? 'Estoque: ${widget.stock.toStringAsFixed(widget.stock.truncateToDouble() == widget.stock ? 0 : 1)} ${widget.unit}'
            : 'Estoque: ${widget.stock}';

    return Card(
      margin: const EdgeInsets.all(6.0),
      color: const Color(0xFF333333), // Dark gray background
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section with icon and product name
            Column(
              children: [
                const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 28.0,
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Add price display if price is not null
                if (widget.price != null) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'R\$ ${widget.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50), // Green color for price
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),

            // Middle section with stock information
            Text(
              formattedStock,
              style: TextStyle(
                color: widget.stock <= 0 ? Colors.red : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Bottom section with action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // Button layout based on stock level
  Widget _buildButtons() {
    // Check if stock is zero or less
    final double stock =
        widget.stock is double
            ? widget.stock
            : double.parse(widget.stock.toString());

    if (stock <= 0) {
      return _buildDeleteOnlyButton();
    } else {
      return _buildRegularButtons();
    }
  }

  // Button layout for zero stock - only delete button
  Widget _buildDeleteOnlyButton() {
    return ElevatedButton(
      onPressed: _deleteItem,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF5350), // Red
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, size: 20.0),
          SizedBox(width: 8.0),
          Text('Excluir'),
        ],
      ),
    );
  }

  // Regular button layout with edit and remove buttons
  Widget _buildRegularButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Edit button
        Expanded(
          child: ElevatedButton(
            onPressed: _editItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF607D8B), // Blue-gray
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: const Icon(Icons.edit, size: 20.0),
          ),
        ),
        const SizedBox(width: 8.0),
        // Remove button
        Expanded(
          child: ElevatedButton(
            onPressed: _useItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350), // Red
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: const Icon(Icons.remove_circle_outline, size: 20.0),
          ),
        ),
      ],
    );
  }

  // Function to handle editing an item
  void _editItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditProductScreen(
              codigo: widget.codigo,
              onProductUpdated: widget.onItemUpdated,
            ),
      ),
    ).then((updated) {
      if (updated == true && widget.onItemUpdated != null) {
        widget.onItemUpdated!();
      }
    });
  }

  // Function to handle using an item (decrement stock)
  Future<void> _useItem() async {
    try {
      _logger.info('Using item: ${widget.name} (${widget.codigo})');

      // Check if stock is already 0 or less
      if (widget.stock <= 0) {
        _showToast('Estoque já está em zero', Colors.orange);
        return;
      }

      // If the unit is kg, show a dialog to input the quantity
      if (widget.unit?.toLowerCase() == 'kg') {
        await _showKgQuantityDialog();
      } else {
        // For non-kg items, just remove 1 from stock
        await _inventoryDb.removeStock(widget.codigo, 1);
        _logger.info('Stock decremented for item: ${widget.codigo}');

        // Notify parent to refresh the UI
        if (widget.onItemUpdated != null) {
          widget.onItemUpdated!();
        }
      }
    } catch (e) {
      _logger.error('Error using item: $e');
      _showToast('Erro ao atualizar estoque: $e', Colors.red);
    }
  }

  // Function to handle deleting an item
  Future<void> _deleteItem() async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Excluir Item'),
              content: Text('Tem certeza que deseja excluir "${widget.name}"?'),
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
        _logger.info('Deleting item: ${widget.codigo}');

        // Directly call the removeItem method from the inventory database
        await _inventoryDb.removeItem(widget.codigo);

        _showToast('Item excluído com sucesso', Colors.green);

        // Notify parent to refresh the UI
        if (widget.onItemUpdated != null) {
          widget.onItemUpdated!();
        }
      }
    } catch (e) {
      _logger.error('Error deleting item: $e');
      _showToast('Erro ao excluir item: $e', Colors.red);
    }
  }

  // Helper method to show toast notification
  void _showToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Show dialog for kg quantity input
  Future<void> _showKgQuantityDialog() async {
    // Create a text editing controller with the current stock as default value
    final TextEditingController quantityController = TextEditingController(
      text: widget.stock.toString(),
    );

    // Variable to store the quantity to remove
    double? quantityToRemove;

    // Show the dialog and wait for result
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remover quantidade de ${widget.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Estoque atual: ${widget.stock} kg'),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade a remover (kg)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Try to parse the input value
                  try {
                    final inputValue = double.parse(quantityController.text);

                    // Validate the input
                    if (inputValue <= 0) {
                      _showToast(
                        'Quantidade deve ser maior que zero',
                        Colors.orange,
                      );
                      return;
                    }

                    if (inputValue > widget.stock) {
                      _showToast(
                        'Quantidade não pode ser maior que o estoque',
                        Colors.orange,
                      );
                      return;
                    }

                    // Store the valid quantity and close the dialog
                    quantityToRemove = inputValue;
                    Navigator.pop(context, true);
                  } catch (e) {
                    _showToast('Valor inválido', Colors.red);
                  }
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    // If dialog was confirmed and we have a valid quantity
    if (result == true && quantityToRemove != null) {
      _logger.info('Removing $quantityToRemove kg from ${widget.codigo}');

      // Update the inventory
      await _inventoryDb.removeStock(widget.codigo, quantityToRemove!);

      // Notify parent to refresh the UI
      if (widget.onItemUpdated != null) {
        widget.onItemUpdated!();
      }

      _showToast('Removido $quantityToRemove kg com sucesso', Colors.green);
    }
  }
}
