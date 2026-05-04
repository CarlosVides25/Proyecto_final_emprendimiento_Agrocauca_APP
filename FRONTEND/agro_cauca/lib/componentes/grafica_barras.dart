import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficaBarras extends StatelessWidget {
  final double inversion;
  final double venta;

  const GraficaBarras({super.key, required this.inversion, required this.venta});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Balance General", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (venta > inversion ? venta : inversion) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500);
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(value == 0 ? "Inversión" : "Venta", style: style),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _buildGroup(0, inversion, [Colors.blue.shade300, Colors.blue.shade700]),
                  _buildGroup(1, venta, [Colors.green.shade300, Colors.green.shade700]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildGroup(int x, double y, List<Color> colors) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(colors: colors, begin: Alignment.bottomCenter, end: Alignment.topCenter),
          width: 35,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: y * 1.1, color: Colors.grey.withOpacity(0.1)),
        ),
      ],
    );
  }
}