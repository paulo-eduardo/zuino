import 'package:flutter/material.dart';
import 'package:zuino/database/product_database.dart';
import 'package:zuino/database/receipts_database.dart';
import 'package:zuino/utils/logger.dart';
import 'package:zuino/utils/toast_manager.dart'; // Add this import
import 'package:fl_chart/fl_chart.dart'; // You'll need to add this package to pubspec.yaml
import 'package:zuino/models/product.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final _logger = Logger('AnalyticsScreen');
  final _productDb = ProductDatabase();
  final _receiptsDb = ReceiptsDatabase();

  bool _isLoading = true;
  Map<String, double> _categorySpending = {};
  List<Map<String, dynamic>> _productSpending = [];
  late TabController _tabController;

  // Colors for the pie chart
  final List<Color> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all products with their categories
      final products = await _productDb.getAllProducts();

      // Get all receipts to calculate spending
      final receipts = await _receiptsDb.getReceipts();

      // Map to store category spending
      final Map<String, double> categorySpending = {};

      // Map to store product spending
      final Map<String, Map<String, dynamic>> productSpendingMap = {};

      // Process all receipts and their items
      for (final receipt in receipts) {
        final items = receipt['items'] as List;

        for (final item in items) {
          final productCode = item['productCode'] as String;
          final quantity = double.parse(item['quantity'].toString());
          final unitValue = double.parse(item['unitValue'].toString());
          final total = quantity * unitValue;

          // Find the product to get its category
          final product = products.firstWhere(
            (p) => p.code == productCode,
            orElse:
                () => Product(
                  code: productCode,
                  name: 'Produto Desconhecido',
                  category: 'Outros',
                  unit: 'un',
                ),
          );

          final category = product.category;
          final productName = product.name;

          // Update category spending
          categorySpending[category] =
              (categorySpending[category] ?? 0) + total;

          // Update product spending
          if (productSpendingMap.containsKey(productCode)) {
            productSpendingMap[productCode]!['total'] += total;
            productSpendingMap[productCode]!['quantity'] += quantity;
          } else {
            productSpendingMap[productCode] = {
              'codigo': productCode,
              'name': productName,
              'category': category,
              'total': total,
              'quantity': quantity,
              'unit': product.unit,
            };
          }
        }
      }

      // Convert product spending map to list and sort by total
      final productSpendingList = productSpendingMap.values.toList();
      productSpendingList.sort(
        (a, b) => (b['total'] as double).compareTo(a['total'] as double),
      );

      if (mounted) {
        setState(() {
          _categorySpending = categorySpending;
          _productSpending = productSpendingList;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error loading analytics data', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastManager.showError('Erro ao carregar dados: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Gastos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Categorias'),
            Tab(icon: Icon(Icons.table_chart), text: 'Produtos'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildCategoryChart(), _buildProductTable()],
              ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categorySpending.isEmpty) {
      return const Center(child: Text('Nenhum dado disponível'));
    }

    // Sort categories by spending amount (descending)
    final sortedCategories =
        _categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total spending
    final totalSpending = _categorySpending.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    // Prepare data for pie chart
    final pieChartSections = <PieChartSectionData>[];

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / totalSpending) * 100;

      pieChartSections.add(
        PieChartSectionData(
          color: _chartColors[i % _chartColors.length],
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PieChart(
              PieChartData(
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final entry = sortedCategories[index];
              final percentage = (entry.value / totalSpending) * 100;

              return ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  color: _chartColors[index % _chartColors.length],
                ),
                title: Text(entry.key),
                trailing: Text(
                  'R\$ ${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable() {
    if (_productSpending.isEmpty) {
      return const Center(child: Text('Nenhum dado disponível'));
    }

    return ListView.builder(
      itemCount: _productSpending.length,
      itemBuilder: (context, index) {
        final product = _productSpending[index];
        final total = product['total'] as double;
        final quantity = product['quantity'] as double;
        final unit = product['unit'] as String;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              product['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Categoria: ${product['category'] as String}\n'
              'Quantidade: ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)} $unit',
            ),
            trailing: Text(
              'R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
