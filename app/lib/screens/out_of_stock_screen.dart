import 'package:flutter/material.dart';
import 'package:mercadinho/database/products_database.dart';

class OutOfStockScreen extends StatefulWidget {
  const OutOfStockScreen({Key? key}) : super(key: key);

  @override
  State<OutOfStockScreen> createState() => _OutOfStockScreenState();
}

class _OutOfStockScreenState extends State<OutOfStockScreen> {
  List<Map<String, dynamic>> _outOfStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutOfStockProducts();
  }

  Future<void> _loadOutOfStockProducts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final products = await ProductsDatabase().getOutOfStockProducts();
      
      setState(() {
        _outOfStockProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading out of stock products: $e');
      setState(() {
        _outOfStockProducts = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProduct(String codigo) async {
    try {
      await ProductsDatabase().removeProduct(codigo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto removido com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOutOfStockProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover produto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Return true to refresh the stock screen
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Produtos em Falta'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Return true to refresh the stock screen
            },
          ),
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _outOfStockProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum produto em falta',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text('Voltar ao Estoque'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _outOfStockProducts.length,
                  itemBuilder: (context, index) {
                    final product = _outOfStockProducts[index];
                    final name = product['name'] as String;
                    final unit = product['unit'] as String;
                    final quantity = product['quantity'] as double;
                    final used = (product['used'] ?? 0.0) as double;
                    final codigo = product['codigo'] as String;
                    
                    return Dismissible(
                      key: Key(codigo),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar exclusão'),
                              content: Text(
                                  'Tem certeza que deseja remover "$name" do estoque?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Remover'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _removeProduct(codigo);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Código: $codigo'),
                              Text('Unidade: $unit'),
                              Text(
                                'Estoque: ${quantity.toStringAsFixed(2)} | Usado: ${used.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar exclusão'),
                                  content: Text(
                                      'Tem certeza que deseja remover "$name" do estoque?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Remover'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                _removeProduct(codigo);
                              }
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
