import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../domain/models/transaction_model.dart';

class CashflowBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const CashflowBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar y agrupar cronológicamente
    final validTxs = transactions.where((t) => t.type == 'income' || t.type == 'expense').toList();
    if (validTxs.isEmpty) {
      return const Center(child: Text('No hay flujo de fondos para mostrar.', style: TextStyle(color: Colors.grey)));
    }

    // Ordenar de más antiguo a más reciente
    validTxs.sort((a, b) => a.date.compareTo(b.date));

    // Estructura: date (YYYY-MM-DD) -> [Income, Expense]
    final Map<String, List<double>> groupedByDate = {};

    for (var tx in validTxs) {
      final dateOnly = tx.date.split('T')[0].split(' ')[0]; // Seguridad para tomar solo YYYY-MM-DD
      if (!groupedByDate.containsKey(dateOnly)) {
        groupedByDate[dateOnly] = [0.0, 0.0];
      }
      if (tx.type == 'income') {
        groupedByDate[dateOnly]![0] += tx.amount;
      } else {
        groupedByDate[dateOnly]![1] += tx.amount;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedDates = groupedByDate.keys.toList()..sort();
    
    // Obtener el máximo valor para escalar el Y Axis
    double maxY = 0;
    for (var vals in groupedByDate.values) {
      if (vals[0] > maxY) maxY = vals[0];
      if (vals[1] > maxY) maxY = vals[1];
    }
    // Añadir margen del 20%
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100; // Backup

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedDates.length) {
                    final parts = sortedDates[index].split('-');
                    final label = '${parts[2]}/${parts[1]}'; // DD/MM
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Diseño minimalista
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.black12,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedDates.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;
            final income = groupedByDate[date]![0];
            final expense = groupedByDate[date]![1];

            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: const Color(0xFF10b981), // Verde
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: expense,
                  color: const Color(0xFFef4444), // Rojo
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
