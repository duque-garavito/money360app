import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../domain/models/transaction_model.dart';
import '../../../../core/utils/currency_formatter.dart';

class BalanceTrendBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const BalanceTrendBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar y agrupar cronológicamente
    final validTxs = transactions.where((t) => t.type == 'income' || t.type == 'expense').toList();
    if (validTxs.isEmpty) {
      return const Center(child: Text('Datos insuficientes para la tendencia.', style: TextStyle(color: Colors.grey)));
    }

    validTxs.sort((a, b) => a.date.compareTo(b.date));

    // Estructura: date (YYYY-MM-DD) -> Delta (Ingreso - Gasto)
    final Map<String, double> deltaByDate = {};

    for (var tx in validTxs) {
      final dateOnly = tx.date.split('T')[0].split(' ')[0];
      if (!deltaByDate.containsKey(dateOnly)) {
        deltaByDate[dateOnly] = 0.0;
      }
      if (tx.type == 'income') {
        deltaByDate[dateOnly] = deltaByDate[dateOnly]! + tx.amount;
      } else {
        deltaByDate[dateOnly] = deltaByDate[dateOnly]! - tx.amount;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedDates = deltaByDate.keys.toList()..sort();

    // Determinar Y max/min para escalar
    double maxY = 0;
    double minY = 0;
    for (var delta in deltaByDate.values) {
      if (delta > maxY) maxY = delta;
      if (delta < minY) minY = delta;
    }
    
    // Márgenes
    maxY = maxY > 0 ? maxY * 1.2 : 100;
    minY = minY < 0 ? minY * 1.2 : 0;
    
    if (maxY == 0 && minY == 0) maxY = 100;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: minY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? Colors.white : Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  CurrencyFormatter.format(rod.toY),
                  TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            // Dibujar la línea cero más marcada
            getDrawingHorizontalLine: (value) {
              if (value == 0) {
                return FlLine(color: isDark ? Colors.white38 : Colors.black38, strokeWidth: 1.5);
              }
              return FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedDates.asMap().entries.map((entry) {
            final index = entry.key;
            final delta = deltaByDate[entry.value]!;
            final isPositive = delta >= 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: delta,
                  color: isPositive ? const Color(0xFF10b981) : const Color(0xFFef4444),
                  width: 16,
                  borderRadius: isPositive 
                      ? const BorderRadius.vertical(top: Radius.circular(4))
                      : const BorderRadius.vertical(bottom: Radius.circular(4)), // Borde redondo abajo si es negativo
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
