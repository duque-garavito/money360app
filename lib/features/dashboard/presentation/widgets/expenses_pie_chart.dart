import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../domain/models/transaction_model.dart';
import '../../../../domain/models/category_model.dart';
import '../../../../core/utils/currency_formatter.dart';

class ExpensesPieChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const ExpensesPieChart({super.key, required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar solo gastos y agrupar por categoryId calculando la suma
    final Map<String, double> expensesByCategory = {};
    for (var tx in transactions.where((t) => t.type == 'expense')) {
      expensesByCategory[tx.categoryId] = (expensesByCategory[tx.categoryId] ?? 0) + tx.amount;
    }

    if (expensesByCategory.isEmpty) {
      return const Center(child: Text('No hay gastos registrados aún.', style: TextStyle(color: Colors.grey)));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Mapear a PieChartSectionData usando el color de la categoría
    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];

    expensesByCategory.forEach((catId, amount) {
      final category = categories.firstWhere(
        (c) => c.id == catId, 
        orElse: () => CategoryModel(id: '', name: 'Desconocido', type: 'expense', color: '#808080')
      );

      final color = Color(int.parse(category.color.replaceFirst('#', '0xff')));
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: CurrencyFormatter.format(amount),
          radius: 45,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        )
      );

      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(category.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12))),
            ],
          ),
        )
      );
    });

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0, // Sin bordes entre segmentos
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legends,
          ),
        ),
      ],
    );
  }
}
